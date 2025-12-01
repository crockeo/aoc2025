const std = @import("std");

const Direction = enum {
    left,
    right,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("day1_input1.txt", .{});
    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    var pos: i32 = 50;

    var num_ended_at_zero: usize = 0;
    var num_crossed_zero: usize = 0;
    while (lines.next()) |line| {
        const stripped_line = std.mem.trim(u8, line, " \t\n\r");
        if (stripped_line.len == 0) {
            continue;
        }

        const direction: Direction = blk: {
            if (stripped_line[0] == 'L') {
                break :blk .left;
            }
            if (stripped_line[0] == 'R') {
                break :blk .right;
            }
            return error.InvalidChar;
        };

        const magnitude = try std.fmt.parseInt(i32, stripped_line[1..], 10);
        const result = add_pos(pos, direction, magnitude);
        std.debug.print("{} {}; {} --> {} ({})\n", .{ direction, magnitude, pos, result.new_pos, result.crossed_zero });
        pos = result.new_pos;
        if (pos == 0) {
            num_ended_at_zero += 1;
        }
        num_crossed_zero += result.crossed_zero;
    }
    std.debug.print("{} {}\n", .{ num_ended_at_zero, num_crossed_zero });
}

const AddResult = struct {
    crossed_zero: usize,
    new_pos: i32,
};

fn add_pos(pos: i32, dir: Direction, mag: i32) AddResult {
    var result = AddResult{
        .crossed_zero = 0,
        .new_pos = pos,
    };
    switch (dir) {
        .left => {
            result.new_pos -= mag;
        },
        .right => {
            result.new_pos += mag;
        },
    }
    if (pos == 0 and result.new_pos < 0) {
        result.new_pos = 100 + result.new_pos;
    }
    while (result.new_pos < 0) {
        result.crossed_zero += 1;
        result.new_pos = 100 + result.new_pos;
    }
    while (result.new_pos > 100) {
        result.new_pos = result.new_pos - 100;
        result.crossed_zero += 1;
    }
    if (result.new_pos == 0 or result.new_pos == 100) {
        result.new_pos = 0;
        result.crossed_zero += 1;
    }
    return result;
}

test "add_pos -- simple" {
    const result = add_pos(50, .right, 5);
    try std.testing.expectEqual(55, result.new_pos);
    try std.testing.expectEqual(0, result.crossed_zero);
}

test "add_pos -- cross-left" {
    const result = add_pos(50, .left, 55);
    try std.testing.expectEqual(95, result.new_pos);
    try std.testing.expectEqual(1, result.crossed_zero);
}

test "add_pos -- cross-right" {
    const result = add_pos(50, .right, 55);
    try std.testing.expectEqual(5, result.new_pos);
    try std.testing.expectEqual(1, result.crossed_zero);
}

test "add_pos -- left end zero" {
    const result = add_pos(50, .left, 50);
    try std.testing.expectEqual(0, result.new_pos);
    try std.testing.expectEqual(1, result.crossed_zero);
}

test "add_pos -- right end zero" {
    const result = add_pos(50, .right, 50);
    try std.testing.expectEqual(0, result.new_pos);
    try std.testing.expectEqual(1, result.crossed_zero);
}

test "add_pos -- left end zero spin" {
    const result = add_pos(50, .left, 150);
    try std.testing.expectEqual(0, result.new_pos);
    try std.testing.expectEqual(2, result.crossed_zero);
}

test "add_pos -- right end zero spin" {
    const result = add_pos(50, .right, 150);
    try std.testing.expectEqual(0, result.new_pos);
    try std.testing.expectEqual(2, result.crossed_zero);
}

test "add_pos -- avoid double count left" {
    const result = add_pos(0, .left, 50);
    try std.testing.expectEqual(50, result.new_pos);
    try std.testing.expectEqual(0, result.crossed_zero);
}

test "add_pos -- avoid double right" {
    const result = add_pos(0, .right, 100);
    try std.testing.expectEqual(0, result.new_pos);
    try std.testing.expectEqual(1, result.crossed_zero);
}
