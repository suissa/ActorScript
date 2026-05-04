import gleam/dict
import router

pub fn app() -> router.Router {
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
