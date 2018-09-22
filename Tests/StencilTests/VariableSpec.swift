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
  let featuring: Article? = Article(author: Person(name: "Jhon"))
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
      "article": Article(author: Person(name: "Kyle")),
      "tuple": (one: 1, two: 2)
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

    $0.context("given string") {
      $0.it("can resolve an item via it's index") {
        let variable = Variable("name.0")
        let result = try variable.resolve(context) as? Character
        try expect(result) == "K"

        let variable1 = Variable("name.1")
        let result1 = try variable1.resolve(context) as? Character
        try expect(result1) == "y"
      }

      $0.it("can resolve an item via unknown index") {
        let variable = Variable("name.5")
        let result = try variable.resolve(context) as? Character
        try expect(result).to.beNil()

        let variable1 = Variable("name.-5")
        let result1 = try variable1.resolve(context) as? Character
        try expect(result1).to.beNil()
      }

      $0.it("can resolve the first item") {
        let variable = Variable("name.first")
        let result = try variable.resolve(context) as? Character
        try expect(result) == "K"
      }

      $0.it("can resolve the last item") {
        let variable = Variable("name.last")
        let result = try variable.resolve(context) as? Character
        try expect(result) == "e"
      }

      $0.it("can get the characters count") {
        let variable = Variable("name.count")
        let result = try variable.resolve(context) as? Int
        try expect(result) == 4
      }
    }

    $0.context("given dictionary") {
      $0.it("can resolve an item") {
        let variable = Variable("profiles.github")
        let result = try variable.resolve(context) as? String
        try expect(result) == "kylef"
      }

      $0.it("can get the count") {
        let variable = Variable("profiles.count")
        let result = try variable.resolve(context) as? Int
        try expect(result) == 1
      }
    }

    $0.context("given array") {
      $0.it("can resolve an item via it's index") {
        let variable = Variable("contacts.0")
        let result = try variable.resolve(context) as? String
        try expect(result) == "Katie"

        let variable1 = Variable("contacts.1")
        let result1 = try variable1.resolve(context) as? String
        try expect(result1) == "Carlton"
      }

      $0.it("can resolve an item via unknown index") {
        let variable = Variable("contacts.5")
        let result = try variable.resolve(context) as? String
        try expect(result).to.beNil()

        let variable1 = Variable("contacts.-5")
        let result1 = try variable1.resolve(context) as? String
        try expect(result1).to.beNil()
      }

      $0.it("can resolve the first item") {
        let variable = Variable("contacts.first")
        let result = try variable.resolve(context) as? String
        try expect(result) == "Katie"
      }

      $0.it("can resolve the last item") {
        let variable = Variable("contacts.last")
        let result = try variable.resolve(context) as? String
        try expect(result) == "Carlton"
      }

      $0.it("can get the count") {
        let variable = Variable("contacts.count")
        let result = try variable.resolve(context) as? Int
        try expect(result) == 2
      }
    }

    $0.it("can resolve a property with reflection") {
      let variable = Variable("article.author.name")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Kyle"
    }

    $0.it("can resolve rawValue") {
      enum SomeEnum: String, DynamicMemberLookup {
        case someValue = "this is raw value"
      }
      let variable = Variable("enum.rawValue")
      let result = try variable.resolve(Context(dictionary: ["enum": SomeEnum.someValue])) as? String
      try expect(result) == "this is raw value"
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

    $0.it("does not crash on KVO") {
      let variable = Variable("object.fullname")
      let result = try variable.resolve(context) as? String
      try expect(result).to.beNil()
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

    $0.it("can resolve optional variable property using reflection") {
      let variable = Variable("blog.featuring.author.name")
      let result = try variable.resolve(context) as? String
      try expect(result) == "Jhon"
    }

    $0.it("does not render Optional") {
      var array: [Any?] = [1, nil]
      array.append(array)
      let context = Context(dictionary: ["values": array])

      try expect(VariableNode(variable: "values").render(context)) == "[1, nil, [1, nil]]"
      try expect(VariableNode(variable: "values.1").render(context)) == ""
    }

    $0.it("can subscript tuple by index") {
      let variable = Variable("tuple.0")
      let result = try variable.resolve(context) as? Int
      try expect(result) == 1
    }

    $0.it("can subscript tuple by label") {
      let variable = Variable("tuple.two")
      let result = try variable.resolve(context) as? Int
      try expect(result) == 2
    }

    $0.describe("Subscripting") {
      $0.it("can resolve a property subscript via reflection") {
        try context.push(dictionary: ["property": "name"]) {
          let variable = Variable("article.author[property]")
          let result = try variable.resolve(context) as? String
          try expect(result) == "Kyle"
        }
      }

      $0.it("can subscript an array with a valid index") {
        try context.push(dictionary: ["property": 0]) {
          let variable = Variable("contacts[property]")
          let result = try variable.resolve(context) as? String
          try expect(result) == "Katie"
        }
      }

      $0.it("can subscript an array with an unknown index") {
        try context.push(dictionary: ["property": 5]) {
          let variable = Variable("contacts[property]")
          let result = try variable.resolve(context) as? String
          try expect(result).to.beNil()
        }
      }

#if os(OSX)
      $0.it("can resolve a subscript via KVO") {
        try context.push(dictionary: ["property": "name"]) {
          let variable = Variable("object[property]")
          let result = try variable.resolve(context) as? String
          try expect(result) == "Foo"
        }
      }
#endif

      $0.it("can resolve an optional subscript via reflection") {
        try context.push(dictionary: ["property": "featuring"]) {
          let variable = Variable("blog[property].author.name")
          let result = try variable.resolve(context) as? String
          try expect(result) == "Jhon"
        }
      }

      $0.it("can resolve multiple subscripts") {
        try context.push(dictionary: [
          "prop1": "articles",
          "prop2": 0,
          "prop3": "name"
        ]) {
          let variable = Variable("blog[prop1][prop2].author[prop3]")
          let result = try variable.resolve(context) as? String
          try expect(result) == "Kyle" 
        }
      }

      $0.it("can resolve nested subscripts") {
        try context.push(dictionary: [
          "prop1": "prop2",
          "ref": ["prop2": "name"]
        ]) {
          let variable = Variable("article.author[ref[prop1]]")
          let result = try variable.resolve(context) as? String
          try expect(result) == "Kyle" 
        }
      }

      $0.it("throws for invalid keypath syntax") {
        try context.push(dictionary: ["prop": "name"]) {
          let samples = [
            ".",
            "..",
            ".test",
            "test..test",
            "[prop]",
            "article.author[prop",
            "article.author[[prop]",
            "article.author[prop]]",
            "article.author[]",
            "article.author[[]]",
            "article.author[prop][]",
            "article.author[prop]comments",
            "article.author[.]"
          ]

          for lookup in samples {
            let variable = Variable(lookup)
            try expect(variable.resolve(context)).toThrow()  
          }
        }
      }
    }
  }

  describe("RangeVariable") {

    let context: Context = {
      let ext = Extension()
      ext.registerFilter("incr", filter: { (arg: Any?) in toNumber(value: arg!)! + 1 })
      let environment = Environment(extensions: [ext])
      return Context(dictionary: [:], environment: environment)
    }()

    func makeVariable(_ token: String) throws -> RangeVariable? {
      let token = Token.variable(value: token, at: .unknown)
      let parser = TokenParser(tokens: [token], environment: context.environment)
      return try RangeVariable(token.contents, parser: parser, containedIn: token)
    }

    $0.it("can resolve closed range as array") {
      let result = try makeVariable("1...3")?.resolve(context) as? [Int]
      try expect(result) == [1, 2, 3]
    }

    $0.it("can resolve decreasing closed range as reversed array") {
      let result = try makeVariable("3...1")?.resolve(context) as? [Int]
      try expect(result) == [3, 2, 1]
    }

    $0.it("can use filter on range variables") {
      let result = try makeVariable("1|incr...3|incr")?.resolve(context) as? [Int]
      try expect(result) == [2, 3, 4]
    }

    $0.it("throws when left value is not int") {
      let template: Template = "{% for i in k...j %}{{ i }}{% endfor %}"
      try expect(try template.render(Context(dictionary: ["j": 3, "k": "1"]))).toThrow()
    }

    $0.it("throws when right value is not int") {
      let variable = try makeVariable("k...j")
      try expect(try variable?.resolve(Context(dictionary: ["j": "3", "k": 1]))).toThrow()
    }

    $0.it("throws is left range value is missing") {
      try expect(makeVariable("...1")).toThrow()
    }

    $0.it("throws is right range value is missing") {
      try expect(makeVariable("1...")).toThrow()
    }

  }

  describe("inline if expression") {

    $0.it("can conditionally render variable") {
      let template: Template = "{{ variable if variable|uppercase == \"A\" }}"
      try expect(template.render(Context(dictionary: ["variable": "a"]))) == "a"
      try expect(template.render(Context(dictionary: ["variable": "b"]))) == ""
    }

    $0.it("can render with else expression") {
      let template: Template = "{{ variable if variable|uppercase == \"A\" else fallback|uppercase }}"
      try expect(template.render(Context(dictionary: ["variable": "b", "fallback": "c"]))) == "C"
    }

    $0.it("throws when used invalid condition") {
      let template: Template = "{{ variable if variable \"A\" }}"
      try expect(template.render(Context(dictionary: ["variable": "a"]))).toThrow()
    }
  }
}
