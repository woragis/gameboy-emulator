const std = @import("std");

const Registers = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    h: u8,
    l: u8,
    f: u8,
    pc: u16, // Program Counter
    sp: u16, // Stack Pointer (later)
};

const Cpu = struct {
    memory: [0x10000]u8, // 64KB of memory
    registers: Registers,

    pub fn init() Cpu {
        return Cpu{
            .memory = undefined,
            .registers = Registers{
                .a = 0, // General purpose registers
                .b = 0, // General purpose registers
                .c = 0, // General purpose registers
                .d = 0, // General purpose registers
                .e = 0, // General purpose registers
                .h = 0, // General purpose registers
                .l = 0, // General purpose registers
                .f = 0, // Flag register
                .pc = 0x0100, // Program starts at 0x0100
                .sp = 0xFFFE, // Stack Pointer
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

    pub fn run(self: *Cpu) void {
        while (true) {
            const opcode = self.read_memory(self.registers.pc);
            self.registers.pc += 1;
            self.execute_opcode(opcode);
        }
    }

    fn execute_opcode(self: *Cpu, opcode: u8) void {
        switch (opcode) {
            0x00 => {}, // NOP
            0xC3 => { // JP nn
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const address = (@as(u16, high) << 8) | low;
                self.registers.pc = address;
            },
            0x3E => { // LD A, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.a = value;
            },
            0x05 => { // DEC B
                self.registers.b -%= 1;
                // Later you will handle flags (Z, N, H)
            },
            0x06 => { // LD B, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.b = value;
            },
            0x0E => { // LD C, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.c = value;
            },
            0x20 => { // JR NZ, r8
                const offset = @as(u16, @bitCast(@as(u16, self.read_memory(self.registers.pc))));
                self.registers.pc +%= 1;
                if (self.registers.f & 0x80 == 0) { // Z flag not set
                    self.registers.pc +%= @as(u16, offset);
                }
            },
            0x21 => { // LD HL, d16
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.h = high;
                self.registers.l = low;
            },
            0x32 => { // LD (HL-), A
                const address = (@as(u16, self.registers.h) << 8) | self.registers.l;
                self.memory[address] = self.registers.a;

                const new_hl = address - 1;
                self.registers.h = @truncate(new_hl >> 8);
                self.registers.l = @truncate(new_hl);
            },
            0xAF => { // XOR A
                self.registers.a ^= self.registers.a;
            },
            0xC9 => { // RET
                const low = self.read_memory(self.registers.sp);
                self.registers.sp += 1;
                const high = self.read_memory(self.registers.sp);
                self.registers.sp += 1;
                const address = (@as(u16, high) << 8) | low;
                self.registers.pc = address;
            },
            0xCD => { // CALL nn
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const address = (@as(u16, high) << 8) | low;

                self.registers.sp -= 2;
                const sp = self.registers.sp;
                self.memory[sp] = @truncate(self.registers.pc >> 8);
                self.memory[sp + 1] = @truncate(self.registers.pc);

                self.registers.pc = address;
            },
            0x04 => { // INC B
                self.registers.b += 1;
            },
            0x0C => { // INC C
                self.registers.c += 1;
            },
            else => {
                std.debug.print("Unknown opcode: {X}\n", .{opcode});
                unreachable;
            },
        }
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try stdout.print("Enter path to .gb file: ", .{});

    var input_buffer: [256]u8 = undefined;
    const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
    const path = std.mem.trimRight(u8, input orelse "", "\r\n");

    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const rom = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // Read up to 10MB
    defer allocator.free(rom);

    var cpu = Cpu.init();
    cpu.load_rom(rom);

    try stdout.print("Loaded ROM successfully!\n", .{});

    cpu.run();
    try stdout.print("CPU execution finished.\n", .{});
}
