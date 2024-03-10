const print = @import("std").debug.print;
const mem = @import("std").mem;

pub fn main() void {
    const bytes = "hello";

    print("{}\n", .{@TypeOf(bytes)}); // *const [5:0]u8
    print("{d}\n", .{bytes.len}); // 5
    print("{c}\n", .{bytes[1]}); // e
    print("{d}\n", .{bytes[4]}); // 0
    print("{d}\n", .{bytes[5]}); // 0

    print("{}\n", .{'e' == '\x65'}); // true
    print("{d}\n", .{'\u{1f4a9}'}); // 128169
    print("{d}\n", .{'💯'}); // 128175

    print("{u}\n", .{'💯'});
    print("{u}\n", .{'⚡'});

    print("{}\n", .{mem.eql(u8, "hello", "h\x65llo")}); //true
    print("{}\n", .{mem.eql(u8, "💯", "\xf0\x9f\x92\xaf")}); //true

    const invalid_utf8 = "\xff\xfe";
    print("0x{x}\n", .{invalid_utf8[1]});
    print("0x{x}\n", .{"💯"[1]});
}
