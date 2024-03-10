const std = @import("std");
const expect = std.testing.expect;

fn add(a: i32, b: i32) i32 {
    return a + b;
}

var y: i32 = add(10, x);
const x: i32 = add(12, 34);

test "container level vars" {
    try expect(x == 46);
    try expect(y == 56);
}
