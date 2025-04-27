const std = @import("std");

const Cpu = struct {
    registers: Registers,
    memory: *Memory,

    pub fn step(self: *Cpu) void {
        const opcode = self.memory.read8(self.registers.pc);
        self.registers.pc += 1;
        self.executeOpcode(opcode);
    }

    fn executeOpcode(self: *Cpu, opcode: u8) void {
        // Decode and execute the instruction
        // Example: LD B, n
        switch (opcode) {
            0x06 => {
                const value = self.memory.read8(self.registers.pc);
                self.registers.b = value;
                self.registers.pc += 1;
            },
            else => {
                std.debug.print("Unknown opcode: {x}\n", .{opcode});
            },
        }
    }
};

const Registers = struct {
    pc: u16, // Program Counter
    sp: u16, // Stack Pointer
    a: u8, // Accumulator
    b: u8, // General purpose register
    c: u8, // Accumulator
    d: u8, // General purpose register
    e: u8, // Accumulator
    h: u8, // General purpose register
    l: u8, // Accumulator
    f: u8, // General purpose register
};

const Memory = struct {
    data: [0x10000]u8, // 64KB of memory

    pub fn read8(self: *Memory, address: u16) u8 {
        return self.data[address];
    }

    pub fn write8(self: *Memory, address: u16, value: u8) void {
        self.data[address] = value;
    }
};

pub fn main() !void {
    var memory = Memory{ .data = [_]u8{0} ** 0x10000 };
    var cpu = Cpu{
        .registers = Registers{
            .pc = 0x0000,
            .sp = 0xFFFE,
            .a = 0,
            .b = 0,
            .c = 0,
            .d = 0,
            .e = 0,
            .h = 0,
            .l = 0,
            .f = 0,
        },
        .memory = &memory,
    };

    while (true) {
        cpu.step();
    }
}
