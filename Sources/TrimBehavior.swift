//
//  File.swift
//  
//
//  Created by Yonas Kolb on 12/11/19.
//

import Foundation

public struct TrimBehavior: Equatable {
  var leading: Trim
  var trailing: Trim

  public enum Trim: Equatable {
    /// nothing
    case none

    /// tabs and spaces
    case whitespace

    /// tabs and spaces and a single new line
    case whitespaceAndOneNewLine

    /// all tabs spaces and newlines
    case whitespaceAndNewLines
  }

  public init(leading: Trim, trailing: Trim) {
    self.leading = leading
    self.trailing = trailing
  }

  /// doesn't touch newlines
  public static let none = TrimBehavior(leading: .none, trailing: .none)

  /// removes whitespace before a block and whitespace and a single newline after a block
  public static let smart = TrimBehavior(leading: .whitespace, trailing: .whitespaceAndOneNewLine)

  /// removes all whitespace and newlines before and after a block
  public static let all = TrimBehavior(leading: .whitespaceAndNewLines, trailing: .whitespaceAndNewLines)

  static func leadingRegex(trim: Trim) -> NSRegularExpression {
    switch trim {
    case .none:
      fatalError("No RegularExpression for none")
    case .whitespace:
      return TrimBehavior.leadingWhitespace
    case .whitespaceAndOneNewLine:
      return TrimBehavior.leadingWhitespaceAndOneNewLine
    case .whitespaceAndNewLines:
      return TrimBehavior.leadingWhitespaceAndNewlines
    }
  }

  static func trailingRegex(trim: Trim) -> NSRegularExpression {
    switch trim {
    case .none:
      fatalError("No RegularExpression for none")
    case .whitespace:
      return TrimBehavior.trailingWhitespace
    case .whitespaceAndOneNewLine:
      return TrimBehavior.trailingWhitespaceAndOneNewLine
    case .whitespaceAndNewLines:
      return TrimBehavior.trailingWhitespaceAndNewLines
    }
  }

  //swiftlint:disable force_try
  private static let leadingWhitespaceAndNewlines = try! NSRegularExpression(pattern: "^\\s+")
  private static let trailingWhitespaceAndNewLines = try! NSRegularExpression(pattern: "\\s+$")

  private static let leadingWhitespaceAndOneNewLine = try! NSRegularExpression(pattern: "^[ \t]*\n")
  private static let trailingWhitespaceAndOneNewLine = try! NSRegularExpression(pattern: "\n[ \t]*$")

  private static let leadingWhitespace = try! NSRegularExpression(pattern: "^[ \t]*")
  private static let trailingWhitespace = try! NSRegularExpression(pattern: "[ \t]*$")

  public static func == (lhs: TrimBehavior, rhs: TrimBehavior) -> Bool {
    return lhs.leading == rhs.leading && lhs.trailing == rhs.trailing
  }

}
