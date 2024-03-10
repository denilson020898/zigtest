const std = @import("std");
const x = 1234;

fn foo() void {
    const y = 5678;
    _ = y;
    // y += 1;
}

pub fn main() void {
    var xx: i32 = undefined;
    std.debug.print("{d}, {d}", .{ xx, x });
    xx = x;
    std.debug.print("{d}, {d}", .{ xx, x });
    foo();
}
