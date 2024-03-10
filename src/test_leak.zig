const std = @import("std");

test "detect leak" {
    var list = std.ArrayList(u21).init(std.testing.allocator);
    // defer list.deinit(); //comment this
    try list.append('☔');
    try std.testing.expect(list.items.len == 1);
}
