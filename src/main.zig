const std = @import("std");

const Cpu = struct {
    memory: [0x10000]u8, // 64KB of memory
    registers: Registers,

    pub fn init() Cpu {
        return Cpu{
            .memory = undefined,
            .registers = Registers{
                .pc = 0x0100, // GameBoy starts executing at 0x0100
            },
        };
    }

    pub fn load_rom(self: *Cpu, rom: []const u8) void {
        for (rom, 0..) |byte, i| {
            if (i < self.memory.len) {
                self.memory[i] = byte;
            }
        }
    }

    fn read_memory(self: *Cpu, address: u16) u8 {
        return self.memory[address];
    }

    pub fn step(self: *Cpu) void {
        const opcode = self.read_memory(self.registers.pc);
        self.execute(opcode);
    }

    fn execute(self: *Cpu, opcode: u8) void {
        switch (opcode) {
            0x00 => { // NOP
                self.registers.pc = self.registers.pc +% 1;
            },
            0xC3 => { // JP nn
                const low = self.read_memory(self.registers.pc +% 1);
                const high = self.read_memory(self.registers.pc +% 2);
                const address = (@as(u16, high) << 8) | low;
                self.registers.pc = address;
            },
            else => {
                std.debug.print("Unknown opcode: {x}\n", .{opcode});
                std.process.exit(1);
            },
        }
    }
};

const Registers = struct {
    pc: u16, // Program Counter
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        std.debug.print("Usage: {s} rom.gb\n", .{args[0]});
        return error.MissingROM;
    }

    const rom_path = args[1];
    const file = try std.fs.cwd().openFile(rom_path, .{});
    defer file.close();

    const stat = try file.stat();
    const rom_size = stat.size;
    const rom = try allocator.alloc(u8, rom_size);
    _ = try file.readAll(rom);

    var cpu = Cpu.init();
    cpu.load_rom(rom);

    while (true) {
        cpu.step();
    }
}
