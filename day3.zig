const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("day3_input.txt", .{});
    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');

    var two_sum: usize = 0;
    var twelve_sum: usize = 0;
    while (lines.next()) |line| {
        const stripped_line = std.mem.trim(u8, line, " \t\n\r");

        const max_two_selection = try get_max_selection(allocator, stripped_line, 2);
        defer allocator.free(max_two_selection);

        const max_twelve_selection = try get_max_selection(allocator, stripped_line, 12);
        defer allocator.free(max_twelve_selection);

        const two_value = convert_to_number(max_two_selection);
        const twelve_value = convert_to_number(max_twelve_selection);

        two_sum += two_value;
        twelve_sum += twelve_value;
    }
    std.debug.print("=== Answer ===\n{}\n{}\n", .{ two_sum, twelve_sum });
}

fn get_max_selection(allocator: std.mem.Allocator, line: []const u8, width: usize) ![]const u8 {
    var selection = std.ArrayList(u8).empty;
    for (0.., line) |i, char| {
        const insertion_point = get_insertion_point(
            line,
            width,
            selection.items,
            i,
            char,
        ) orelse {
            continue;
        };

        while (selection.items.len > insertion_point) {
            _ = selection.pop();
        }
        try selection.append(allocator, char);
    }
    return try selection.toOwnedSlice(allocator);
}

fn get_insertion_point(
    line: []const u8,
    width: usize,
    items: []const u8,
    search_index: usize,
    char: u8,
) ?usize {
    const chars_left = line.len - search_index;
    const chars_required = width - items.len;
    if (chars_left <= chars_required) {
        return items.len;
    }

    for (0.., items) |i, item| {
        const prospective_chars_required = width - i;
        if (char > item and chars_left >= prospective_chars_required) {
            return i;
        }
    }

    if (items.len == width) {
        return null;
    }
    return items.len;
}

fn convert_to_number(selection: []const u8) usize {
    var sum: usize = 0;
    for (selection) |char| {
        sum = sum * 10 + (char - '0');
    }
    return sum;
}

test "max_selection -- basic" {
    const selection = try get_max_selection(std.testing.allocator, "1234", 1);
    defer std.testing.allocator.free(selection);
    try std.testing.expectEqualStrings("4", selection);
}

test "max_selection -- slightly less basic" {
    const selection = try get_max_selection(std.testing.allocator, "4132", 2);
    defer std.testing.allocator.free(selection);
    try std.testing.expectEqualStrings("43", selection);
}
