const std = @import("std");
const testing = std.testing;

pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;

pub fn main() !void {
    _ = printf("Hello, world!\n");
    const msg = "Hello, world!\n";
    const non_null_term_msg: [msg.len]u8 = msg.*;
    _ = printf(&non_null_term_msg);
}

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
