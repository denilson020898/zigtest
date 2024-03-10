const std = @import("std");
const expect = std.testing.expect;

test "namespaced container vars" {
    try expect(foo() == 1234);
    try expect(foo() == 1235);
}

fn foo() i32 {
    const Ssss = struct {
        var x: i32 = 1233;
    };

    Ssss.x += 1;
    return Ssss.x;
}
