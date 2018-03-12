import Foundation
import Spectre
@testable import Stencil


#if os(OSX)
@objc class Superclass: NSObject {
  @objc let name = "Foo"
}
@objc class Object : Superclass {
  @objc let title = "Hello World"
}
#endif

fileprivate struct Person {
  let name: String
}

fileprivate struct Article {
  let author: Person
}

fileprivate class WebSite {
  let url: String = "blog.com"
}

fileprivate class Blog: WebSite {
  let articles: [Article] = [Article(author: Person(name: "Kyle"))]
}

func testVariable() {
  describe("Variable") {
    let context = Context(dictionary: [
      "name": "Kyle",
      "contacts": ["Katie", "Carlton"],
      "profiles": [
        "github": "kylef",
      ],
      "counter": [
        "count": "kylef",
        ],
      "article": Article(author: Person(name: "Kyle"))
    ])

#if os(OSX)
    context["object"] = Object()
#endif
    context["blog"] = Blog()

    $0.it("can resolve a string literal with double quotes") {
      let variable = Variable("\"name\"")
      let result = try variable.resolve(context) as? String
      try expect(result) == "name"
    }

    $0.it("can resolve a string literal with single quotes") {
      let variable = Variable("'name'")
      let result = try variable.resolve(context) as? String
      try expect(result) == "name"
    }

    $0.it("can resolve an integer literal") {
      let variable = Variable("5")
      let result = try variable.resolve(context) as? Int
      try expect(result) == 5
    }

    $0.it("can resolve an float literal") {
      let variable = Variable("3.14")
      let result = try variable.resolve(context) as? Number
      try expect(result) == 3.14
    }

    $0.it("can resolve boolean literal") {
      try expect(Variable("true").resolve(context) as? Bool) == true
      try expect(Variable("false").resolve(context) as? Bool) == false
      try expect(Variable("0").resolve(context) as? Int) == 0
      try expect(Variable("1").resolve(context) as? Int) == 1
    }

    $0.it("can resolve a string variable") {
      let variable = Variable("name")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Kyle"
    }

    $0.it("can resolve an item from a dictionary") {
      let variable = Variable("profiles.github")
      let result = try variable.resolve(context) as? String
      try expect(result) == "kylef"
    }

    $0.it("can resolve an item from an array via it's index") {
      let variable = Variable("contacts.0")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Katie"

        let variable1 = Variable("contacts.1")
        let result1 = try variable1.resolve(context) as? String
        try expect(result1) == "Carlton"
    }

    $0.it("can resolve an item from an array via unknown index") {
      let variable = Variable("contacts.5")
      let result = try variable.resolve(context) as? String
      try expect(result).to.beNil()

      let variable1 = Variable("contacts.-5")
      let result1 = try variable1.resolve(context) as? String
      try expect(result1).to.beNil()
    }

    $0.it("can resolve the first item from an array") {
      let variable = Variable("contacts.first")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Katie"
    }

    $0.it("can resolve the last item from an array") {
      let variable = Variable("contacts.last")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Carlton"
    }

    $0.it("can resolve a property with reflection") {
      let variable = Variable("article.author.name")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Kyle"
    }

    $0.it("can get the count of a dictionary") {
      let variable = Variable("profiles.count")
      let result = try variable.resolve(context) as? Int
      try expect(result) == 1
    }

#if os(OSX)
    $0.it("can resolve a value via KVO") {
      let variable = Variable("object.title")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Hello World"
    }

    $0.it("can resolve a superclass value via KVO") {
      let variable = Variable("object.name")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Foo"
    }
#endif
    
    $0.it("can resolve a value via reflection") {
      let variable = Variable("blog.articles.0.author.name")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Kyle"
    }

    $0.it("can resolve a superclass value via reflection") {
      let variable = Variable("blog.url")
      let result = try variable.resolve(context) as? String
      try expect(result) == "blog.com"
    }

  }
}
