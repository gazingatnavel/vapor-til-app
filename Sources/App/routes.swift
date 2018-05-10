import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Create an acronym in the database.
    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
            return acronym.save(on: req)
        }
    }
    
    // Retrieve all acronyms.
    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).all()
    }
    
    // Retrieve a single acroynm by id.
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }

    // Update an existing acronym.
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            return acronym.save(on: req)
        }
    }
    
    // Delete an acronym by id.
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self).flatMap(to: HTTPStatus.self) { acronym in
            return acronym.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }
    
    // Retrieve acronyms by filtering on short or long term.
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return try Acronym.query(on: req).group(.or) { or in
            try or.filter(\.short == searchTerm)
            try or.filter(\.long == searchTerm)
        }.all()
    }
    
    // Retrieve first acronym.
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        return Acronym.query(on: req).first().map(to: Acronym.self) { acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        }
    }
    
    // Retrieve all acronyms sorted by short.
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return try Acronym.query(on: req).sort(\.short, .ascending).all()
    }
}
