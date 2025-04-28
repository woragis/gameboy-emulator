const std = @import("std");
const memory = @import("memory");
const cpu = @import("cpu");

const ROM_SIZE = 0x10000; // 64KB for the Game Boy ROM
const HEADER_SIZE = 0x100; // Game Boy header size (first 256 bytes)

const ROM_LOAD_SUCCESS = 0;
const ROM_LOAD_ERROR = 1;

const ROM_HEADER = []u8{
    // Example of a valid Game Boy header for "Tetris" ROM (for validation purposes)
    0xCE, 0xED, 0x66, 0x66, 0x6E, 0xA5, 0x51, 0x2E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

const ROM_FILE_HEADER = struct {
    magic: [4]u8, // 'GB' or 'DMG' (Game Boy Magic Code)
    title: [16]u8, // Title of the game
    manufacturer: [4]u8, // Manufacturer Code
    header_checksum: u8, // Checksum of the header
    cart_type: u8, // Cartridge type
    rom_size: u8, // Size of the ROM
    ram_size: u8, // Size of RAM
    region_code: u8, // Region code
    licensee_code: [2]u8, // Licensee code
    version: u8, // Version of the ROM
    header_checksum_2: u8, // Second checksum byte
};

pub const ROMLoader = struct {
    pub fn load_rom(self: *ROMLoader, rom_path: []const u8, _memory: *[0x10000]u8) !void {
        // var _allocator = std.heap.page_allocator;

        // Open ROM file
        var rom_file = try std.fs.openFile(rom_path, .{ .read = true });
        defer rom_file.close();

        // Read the ROM header
        var header: ROM_FILE_HEADER = undefined;
        try rom_file.readAll(&header);

        // Validate the header magic bytes
        if (!std.mem.eql(u8, header.magic[0..2], "GB")) {
            return error.InvalidROM; // Invalid magic number
        }

        // Perform additional header checks if necessary
        try self.verify_header(&header);

        // Load the entire ROM into memory (starting at memory address 0x0100)
        const rom_size = try rom_file.readAll(_memory[0x0100..]);

        // Ensure the ROM size is valid by checking if the file size is sufficient
        if (rom_size == 0) {
            return error.InvalidROMSize; // Invalid ROM size, possibly zero or incomplete
        }

        // Optionally, verify checksum or other ROM properties for further validation
        // This can be added later depending on the need to verify the ROM's integrity.

        // If all checks pass, the ROM is loaded successfully
        return ROM_LOAD_SUCCESS;
    }

    pub fn verify_header(_: *ROMLoader, header: *ROM_FILE_HEADER) !void {
        // Perform checks on the header, such as verifying the cartridge type, ROM size, etc.
        // This can be expanded for more detailed header validation.
        if (!std.mem.eql(u8, header.magic[0..2], "GB")) {
            return error.InvalidMagic;
        }
        // Verify the cartridge type (this should be a supported type)
        const valid_cartridge_types = [_]u8{ 0x00, 0x01, 0x02, 0x03, 0x05, 0x06, 0x0F, 0x10, 0x11 };
        var is_valid_cartridge = false;
        for (valid_cartridge_types) |cartridge_type| {
            if (header.cart_type == cartridge_type) {
                is_valid_cartridge = true;
                break;
            }
        }
        if (!is_valid_cartridge) {
            return error.InvalidCartridgeType;
        }

        // Verify the ROM size (should be one of the valid ROM sizes)
        const valid_rom_sizes = [_]u8{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x52, 0x53, 0x54 };
        var is_valid_rom_size = false;
        for (valid_rom_sizes) |rom_size| {
            if (header.rom_size == rom_size) {
                is_valid_rom_size = true;
                break;
            }
        }
        if (!is_valid_rom_size) {
            return error.InvalidROMSize;
        }

        // Verify the RAM size (should be one of the valid RAM sizes)
        const valid_ram_sizes = [_]u8{ 0x00, 0x01, 0x02, 0x03 };
        var is_valid_ram_size = false;
        for (valid_ram_sizes) |ram_size| {
            if (header.ram_size == ram_size) {
                is_valid_ram_size = true;
                break;
            }
        }
        if (!is_valid_ram_size) {
            return error.InvalidRAMSize;
        }

        // Verify the region code (valid regions for Game Boy)
        const valid_region_codes = [_]u8{ 0x00, 0x01, 0x02 }; // e.g., 0x00 is Japan, 0x01 is North America, etc.
        var is_valid_region = false;
        for (valid_region_codes) |region_code| {
            if (header.region_code == region_code) {
                is_valid_region = true;
                break;
            }
        }
        if (!is_valid_region) {
            return error.InvalidRegionCode;
        }

        // Verify the licensee code (Nintendo is the most common)
        if (header.licensee_code[0] != 0x01 or header.licensee_code[1] != 0x33) { // 0x01, 0x33 is Nintendo's code
            return error.InvalidLicenseeCode;
        }

        // Verify the version (typically 0x00 or 0x01)
        if (header.version != 0x00 and header.version != 0x01) {
            return error.InvalidVersion;
        }

        // If all checks pass, return successfully
        return null;
    }
};
