pub const Registers = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    h: u8,
    l: u8,
    f: u8, // Flag register

    pc: u16, // Program Counter
    sp: u16, // Stack Pointer
    hl: u16, // HL register pair
    de: u16, // DE register pair

    // // Flag bits are stored in the `f` register as individual bits.
    // const ZeroFlag = 0x80; // Bit 7: Zero flag
    // const NegativeFlag = 0x40; // Bit 6: Negative flag
    // const HalfCarryFlag = 0x20; // Bit 5: Half-carry flag
    // const CarryFlag = 0x10; // Bit 4: Carry flag

    // Flag Constants (Bit Masks) declared as 'u8'
    const ZeroFlag: u8 = 0b10000000; // Z flag
    const NegativeFlag: u8 = 0b01000000; // N flag
    const HalfCarryFlag: u8 = 0b00100000; // H flag
    const CarryFlag: u8 = 0b00010000; // C flag

    // Helper methods for accessing the flag bits
    pub fn set_zero_flag(self: *Registers, value: bool) void {
        if (value) {
            self.f |= Registers.ZeroFlag;
        } else {
            self.f &= ~Registers.ZeroFlag;
        }
    }

    pub fn get_zero_flag(self: *Registers) bool {
        return (self.f & Registers.ZeroFlag) != 0;
    }

    pub fn set_negative_flag(self: *Registers, value: bool) void {
        if (value) {
            self.f |= Registers.NegativeFlag;
        } else {
            self.f &= ~Registers.NegativeFlag;
        }
    }

    pub fn get_negative_flag(self: *Registers) bool {
        return (self.f & Registers.NegativeFlag) != 0;
    }

    pub fn set_half_carry_flag(self: *Registers, value: bool) void {
        if (value) {
            self.f |= Registers.HalfCarryFlag;
        } else {
            self.f &= ~Registers.HalfCarryFlag;
        }
    }

    pub fn get_half_carry_flag(self: *Registers) bool {
        return (self.f & Registers.HalfCarryFlag) != 0;
    }

    pub fn set_carry_flag(self: *Registers, value: bool) void {
        if (value) {
            self.f |= Registers.CarryFlag;
        } else {
            self.f &= ~Registers.CarryFlag;
        }
    }

    pub fn get_carry_flag(self: *Registers) bool {
        return (self.f & Registers.CarryFlag) != 0;
    }
};
