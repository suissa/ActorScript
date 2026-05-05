import gleam/dict
import router

pub fn app() -> router.Router {
  let ctx0 = router.context()
  let router.HttpContext(_, get, post, put, patch, delete) = ctx0

  let ctx1 = get("/users/:id", [require_session], get_user)
  let router.HttpContext(_, _, post1, _, _, _) = ctx1

  let ctx2 = post1("/users", [require_session], create_user)
  let router.HttpContext(_, _, _, put1, _, _) = ctx2

  let ctx3 = put1("/users/:id", [require_session], replace_user)
  let router.HttpContext(_, _, _, _, patch1, _) = ctx3

  let ctx4 = patch1("/users/:id", [require_session], patch_user)
  let router.HttpContext(_, _, _, _, _, delete1) = ctx4

  let ctx5 = delete1("/users/:id", [require_session], delete_user)
  router.unwrap(ctx5)
}

pub fn dispatch(method: router.Method, path: String, session: String) -> router.Response {
  let headers = dict.new() |> dict.insert("x-session", session)
  let req = router.Request(method, path, headers, dict.new(), dict.new(), "")
  router.handle(app(), req)
}

fn require_session(req: router.Request, next: router.Handler) -> router.Response {
  let router.Request(_, _, headers, _, _, _) = req
  case dict.get(headers, "x-session") {
    Ok("valid-session") -> next(req)
    _ -> router.text(status: 401, body: "Unauthorized")
  }
}

fn get_user(req: router.Request) -> router.Response {
  let router.Request(_, _, _, _, params, _) = req
  case dict.get(params, "id") {
    Ok(id) -> router.json(status: 200, body: "{\"action\":\"get\",\"id\":\"" <> id <> "\"}")
  router.new()
  |> router.use(request_logger)
  |> router.get("/", fn(_req) { router.ok("hello from BEAMScript Router") })
  |> router.get("/users/:id", user_by_id)
  |> router.post("/users", create_user)
  |> router.get("/assets/*path", static_asset)
}

pub fn dispatch(method: router.Method, path: String) -> router.Response {
  let req =
    router.Request(method, path, dict.new(), dict.new(), dict.new(), "")

  router.handle(app(), req)
}

fn user_by_id(req: router.Request) -> router.Response {
  let router.Request(_, _, _, _, params, _) = req

  case dict.get(params, "id") {
    Ok(id) -> router.json(status: 200, body: "{\"id\":\"" <> id <> "\"}")
    Error(Nil) -> router.text(status: 400, body: "Missing id")
  }
}

fn create_user(_req: router.Request) -> router.Response {
  router.json(status: 201, body: "{\"action\":\"create\"}")
}

fn replace_user(req: router.Request) -> router.Response {
  let router.Request(_, _, _, _, params, _) = req
  case dict.get(params, "id") {
    Ok(id) -> router.json(status: 200, body: "{\"action\":\"replace\",\"id\":\"" <> id <> "\"}")
    Error(Nil) -> router.text(status: 400, body: "Missing id")
  }
}

fn patch_user(req: router.Request) -> router.Response {
  let router.Request(_, _, _, _, params, _) = req
  case dict.get(params, "id") {
    Ok(id) -> router.json(status: 200, body: "{\"action\":\"patch\",\"id\":\"" <> id <> "\"}")
    Error(Nil) -> router.text(status: 400, body: "Missing id")
  }
}

fn delete_user(req: router.Request) -> router.Response {
  let router.Request(_, _, _, _, params, _) = req
  case dict.get(params, "id") {
    Ok(id) -> router.json(status: 200, body: "{\"action\":\"delete\",\"id\":\"" <> id <> "\"}")
    Error(Nil) -> router.text(status: 400, body: "Missing id")
  }
  router.json(status: 201, body: "{\"created\":true}")
}

fn static_asset(req: router.Request) -> router.Response {
  let router.Request(_, _, _, _, params, _) = req

  case dict.get(params, "path") {
    Ok(path) -> router.text(status: 200, body: "asset: " <> path)
    Error(Nil) -> router.text(status: 404, body: "asset not found")
  }
}

fn request_logger(req: router.Request, next: router.Handler) -> router.Response {
  let _ = req
  next(req)
}
