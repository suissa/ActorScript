import gleam/dict
import gleeunit/should
import router

pub fn unit_param_extraction_test() {
  let app =
    router.new()
    |> router.get("/users/:id", [], fn(req) {
      let router.Request(_, _, _, _, params, _) = req
      case dict.get(params, "id") {
        Ok(id) -> router.text(status: 200, body: id)
        Error(Nil) -> router.text(status: 400, body: "missing")
      }
    })

  let req = router.Request(router.Get, "/users/42", dict.new(), dict.new(), dict.new(), "")
  let router.Response(status, _, body) = router.handle(app, req)

  should.equal(status, 200)
  should.equal(body, "42")
}

pub fn unit_session_middleware_blocks_test() {
  let auth = fn(req: router.Request, next: router.Handler) {
    let router.Request(_, _, headers, _, _, _) = req
    case dict.get(headers, "x-session") {
      Ok("valid-session") -> next(req)
      _ -> router.text(status: 401, body: "Unauthorized")
    }
  }

  let app =
    router.new()
    |> router.get("/users/:id", [auth], fn(_req) { router.ok("ok") })

  let req = router.Request(router.Get, "/users/42", dict.new(), dict.new(), dict.new(), "")
  let router.Response(status, _, _) = router.handle(app, req)

  should.equal(status, 401)
}
