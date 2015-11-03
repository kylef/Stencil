import Foundation
import PathKit

/// A class representing a template
public class Template {
  public let parser:TokenParser
  public var context:Context? = nil
  private var nodes:[NodeType]? = nil

  /// Create a template with the given name inside the given bundle
  public convenience init(named:String, inBundle bundle:NSBundle? = nil) throws {
    let useBundle = bundle ??  NSBundle.mainBundle()
    guard let url = useBundle.URLForResource(named, withExtension: nil) else {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    try self.init(URL:url)
  }

  /// Create a template with a file found at the given URL
  public convenience init(URL:NSURL) throws {
    try self.init(path: Path(URL.path!))
  }

  /// Create a template with a file found at the given path
  public convenience init(path:Path) throws {
    self.init(templateString: try path.read())
  }

  /// Create a template with a template string
  public init(templateString:String) {
    let lexer = Lexer(templateString: templateString)
    let tokens = lexer.tokenize()
    parser = TokenParser(tokens: tokens)
  }

  /// Render the given template
  public func render(context:Context? = nil) throws -> String {
    if nodes == nil {
        nodes = try parser.parse()
    }

    self.context = context

    return try renderNodes(nodes!, self.context ?? Context())
  }
}
