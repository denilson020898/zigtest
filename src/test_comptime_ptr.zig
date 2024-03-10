const expectEqual = @import("std").testing.expectEqual;
const print = @import("std").debug.print;

test "comptime ptrs" {
    comptime {
        var x: i32 = 1;
        const ptr = &x;
        ptr.* += 1;
        x += 1;
        try expectEqual(ptr.*, 3);
    }
}

test "@intFromPtr and @ptrFromInt" {
    const ptr: *i32 = @ptrFromInt(0xdeadbee0);
    const addr = @intFromPtr(ptr);
    try expectEqual(@TypeOf(addr), usize);
    try expectEqual(addr, 0xdeadbee0);
}

test "comptime @ptrFromInt deref" {
    comptime {
        const ptr: *i32 = @ptrFromInt(0xdeadbee0);
        const addr = @intFromPtr(ptr);
        try expectEqual(@TypeOf(addr), usize);
        try expectEqual(addr, 0xdeadbee0);
    }
}

test "volatile" {
    const mmio_ptr: *volatile u8 = @ptrFromInt(0x12345678);
    try expectEqual(@TypeOf(mmio_ptr), *volatile u8);
}
