//
//  DDCService.swift
//  Monik
//

import Foundation
import CoreGraphics
import IOKit
import MonikBridge

public class DDCService {
    public static let shared = DDCService()
    
    private let ARM64_DDC_7BIT_ADDRESS: UInt8 = 0x37
    private let ARM64_DDC_DATA_ADDRESS: UInt8 = 0x51
    
    // Exact mapping of displayID -> IOAVService based on IODisplayLocation
    private var displayServices: [CGDirectDisplayID: IOAVService] = [:]
    
    private init() {
        refreshServices()
    }
    
    public func refreshServices() {
        displayServices.removeAll()
        let locServices = getIoregLocationToAVServices()
        
        for candidateID in 1...20 {
            let id = CGDirectDisplayID(candidateID)
            if let unmanagedDict = CoreDisplay_DisplayCreateInfoDictionary(id) {
                let dict = unmanagedDict.takeRetainedValue() as NSDictionary
                if let loc = dict["IODisplayLocation"] as? String,
                   let avService = locServices[loc] {
                    displayServices[id] = avService
                }
            }
        }
    }
    
    private func getIoregLocationToAVServices() -> [String: IOAVService] {
        var map: [String: IOAVService] = [:]
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        guard root != 0 else { return map }
        defer { IOObjectRelease(root) }
        
        var iter = io_iterator_t()
        guard IORegistryEntryCreateIterator(root, "IOService", IOOptionBits(kIORegistryIterateRecursively), &iter) == KERN_SUCCESS else {
            return map
        }
        defer { IOObjectRelease(iter) }
        
        var entry = IOIteratorNext(iter)
        var lastFramebufferPath = ""
        while entry != 0 {
            let nameBuf = UnsafeMutablePointer<CChar>.allocate(capacity: 128)
            let pathBuf = UnsafeMutablePointer<CChar>.allocate(capacity: 512)
            defer { nameBuf.deallocate(); pathBuf.deallocate() }
            
            IORegistryEntryGetName(entry, nameBuf)
            IORegistryEntryGetPath(entry, kIOServicePlane, pathBuf)
            let name = String(cString: nameBuf)
            let path = String(cString: pathBuf)
            
            if name == "AppleCLCD2" || name == "IOMobileFramebufferShim" {
                lastFramebufferPath = path
            }
            
            if name.contains("DCPAVServiceProxy") {
                if let unmanagedLocation = IORegistryEntryCreateCFProperty(entry, "Location" as CFString, kCFAllocatorDefault, 0),
                   let location = unmanagedLocation.takeRetainedValue() as? String,
                   location == "External" {
                    if let avService = IOAVServiceCreateWithService(kCFAllocatorDefault, entry) {
                        map[lastFramebufferPath] = avService.takeRetainedValue()
                    }
                }
            }
            
            IOObjectRelease(entry)
            entry = IOIteratorNext(iter)
        }
        return map
    }
    
    public func setBrightness(displayID: CGDirectDisplayID, value: Int) -> Bool {
        return writeVCP(displayID: displayID, command: 0x10, value: UInt16(clamping: value))
    }
    
    public func setContrast(displayID: CGDirectDisplayID, value: Int) -> Bool {
        return writeVCP(displayID: displayID, command: 0x12, value: UInt16(clamping: value))
    }
    
    public func setVolume(displayID: CGDirectDisplayID, value: Int) -> Bool {
        return writeVCP(displayID: displayID, command: 0x62, value: UInt16(clamping: value))
    }
    
    public func setMute(displayID: CGDirectDisplayID, isMuted: Bool) -> Bool {
        return writeVCP(displayID: displayID, command: 0x8D, value: isMuted ? 1 : 2)
    }
    
    public func setInputSource(displayID: CGDirectDisplayID, code: UInt16) -> Bool {
        return writeVCP(displayID: displayID, command: 0x60, value: code)
    }
    
    public func setPower(displayID: CGDirectDisplayID, powerOn: Bool) -> Bool {
        if powerOn {
            return writeVCP(displayID: displayID, command: 0xD6, value: 1)
        } else {
            // Send both DPMS Off (4) and Soft Power Off (5) for wide monitor compatibility
            _ = writeVCP(displayID: displayID, command: 0xD6, value: 4)
            _ = writeVCP(displayID: displayID, command: 0xD6, value: 5)
            return true
        }
    }
    
    public func writeVCP(displayID: CGDirectDisplayID, command: UInt8, value: UInt16) -> Bool {
        guard let service = displayServices[displayID] else {
            return false
        }
        var send: [UInt8] = [command, UInt8(value >> 8), UInt8(value & 0xFF)]
        var reply: [UInt8] = []
        return performDDC(service: service, send: &send, reply: &reply)
    }
    
    public func readVCP(displayID: CGDirectDisplayID, command: UInt8) -> (current: UInt16, max: UInt16)? {
        guard let service = displayServices[displayID] else {
            return nil
        }
        var send: [UInt8] = [command]
        var reply = [UInt8](repeating: 0, count: 11)
        if performDDC(service: service, send: &send, reply: &reply) {
            let maxVal = UInt16(reply[6]) * 256 + UInt16(reply[7])
            let curVal = UInt16(reply[8]) * 256 + UInt16(reply[9])
            return (curVal, maxVal)
        }
        return nil
    }
    
    private func performDDC(service: IOAVService, send: inout [UInt8], reply: inout [UInt8]) -> Bool {
        let dataAddress = ARM64_DDC_DATA_ADDRESS
        var packet: [UInt8] = [UInt8(0x80 | (send.count + 1)), UInt8(send.count)] + send + [0]
        packet[packet.count - 1] = checksum(chk: send.count == 1 ? ARM64_DDC_7BIT_ADDRESS << 1 : (ARM64_DDC_7BIT_ADDRESS << 1) ^ dataAddress, data: &packet, start: 0, end: packet.count - 2)
        
        var success = false
        for _ in 0..<3 {
            usleep(10000)
            let writeRet = IOAVServiceWriteI2C(service, UInt32(ARM64_DDC_7BIT_ADDRESS), UInt32(dataAddress), &packet, UInt32(packet.count))
            success = (writeRet == 0)
            
            if !reply.isEmpty {
                usleep(40000)
                if IOAVServiceReadI2C(service, UInt32(ARM64_DDC_7BIT_ADDRESS), UInt32(dataAddress), &reply, UInt32(reply.count)) == 0 {
                    let expectedChk = checksum(chk: 0x50, data: &reply, start: 0, end: reply.count - 2)
                    if expectedChk == reply[reply.count - 1] {
                        return true
                    }
                }
            } else if success {
                return true
            }
            usleep(15000)
        }
        return success
    }
    
    private func checksum(chk: UInt8, data: inout [UInt8], start: Int, end: Int) -> UInt8 {
        var result = chk
        for i in start...end {
            result ^= data[i]
        }
        return result
    }
}
