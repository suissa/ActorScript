import gleam/dict
import gleam/list
import gleam/string

pub type Method {
  Get
  Post
  Put
  Patch
  Delete
}

pub type Request {
  Request(
    method: Method,
    path: String,
    headers: dict.Dict(String, String),
    query: dict.Dict(String, String),
    params: dict.Dict(String, String),
    body: String,
  )
}

pub type Response {
  Response(status: Int, headers: dict.Dict(String, String), body: String)
}

pub type Handler = fn(Request) -> Response
pub type Middleware = fn(Request, Handler) -> Response

pub type Segment {
  Static(String)
  Param(String)
}

pub type Route {
  Route(
    methods: List(Method),
    pattern: String,
    segments: List(Segment),
    middlewares: List(Middleware),
    handler: Handler,
  )
}

pub type Router {
  Router(routes: List(Route), global_middlewares: List(Middleware), not_found: Handler)
}

pub type HttpContext {
  HttpContext(
    router: Router,
    get: fn(String, List(Middleware), Handler) -> HttpContext,
    post: fn(String, List(Middleware), Handler) -> HttpContext,
    put: fn(String, List(Middleware), Handler) -> HttpContext,
    patch: fn(String, List(Middleware), Handler) -> HttpContext,
    delete: fn(String, List(Middleware), Handler) -> HttpContext,
  )
}

pub fn new() -> Router {
  Router([], [], default_not_found)
}

pub fn context() -> HttpContext {
  from_router(new())
}

pub fn from_router(router: Router) -> HttpContext {
  HttpContext(
    router,
    fn(path, middlewares, handler) {
      from_router(route(router, [Get], path, middlewares, handler))
    },
    fn(path, middlewares, handler) {
      from_router(route(router, [Post], path, middlewares, handler))
    },
    fn(path, middlewares, handler) {
      from_router(route(router, [Put], path, middlewares, handler))
    },
    fn(path, middlewares, handler) {
      from_router(route(router, [Patch], path, middlewares, handler))
    },
    fn(path, middlewares, handler) {
      from_router(route(router, [Delete], path, middlewares, handler))
    },
  )
}

pub fn unwrap(context: HttpContext) -> Router {
  let HttpContext(router, _, _, _, _, _) = context
  router
}

pub fn with_not_found(router: Router, handler: Handler) -> Router {
  let Router(routes, global_middlewares, _) = router
  Router(routes, global_middlewares, handler)
}

pub fn use(router: Router, middleware: Middleware) -> Router {
  let Router(routes, global_middlewares, not_found) = router
  Router(routes, list.append(global_middlewares, [middleware]), not_found)
}

pub fn get(router: Router, pattern: String, middlewares: List(Middleware), handler: Handler) -> Router {
  route(router, [Get], pattern, middlewares, handler)
}

pub fn post(router: Router, pattern: String, middlewares: List(Middleware), handler: Handler) -> Router {
  route(router, [Post], pattern, middlewares, handler)
}

pub fn put(router: Router, pattern: String, middlewares: List(Middleware), handler: Handler) -> Router {
  route(router, [Put], pattern, middlewares, handler)
}

pub fn patch(router: Router, pattern: String, middlewares: List(Middleware), handler: Handler) -> Router {
  route(router, [Patch], pattern, middlewares, handler)
}

pub fn delete(router: Router, pattern: String, middlewares: List(Middleware), handler: Handler) -> Router {
  route(router, [Delete], pattern, middlewares, handler)
}

pub fn route(
  router: Router,
  methods: List(Method),
  pattern: String,
  middlewares: List(Middleware),
  handler: Handler,
) -> Router {
  let Router(routes, global_middlewares, not_found) = router
  let entry = Route(methods, pattern, parse_pattern(pattern), middlewares, handler)
  Router(list.append(routes, [entry]), global_middlewares, not_found)
}

pub fn handle(router: Router, request: Request) -> Response {
  let Router(routes, global_middlewares, not_found) = router

  case find_route(routes, request) {
    Ok(tuple(route_middlewares, handler, with_params)) ->
      run_middlewares(
        list.append(global_middlewares, route_middlewares),
        with_params,
        handler,
      )
    Error(Nil) -> run_middlewares(global_middlewares, request, not_found)
  }
}

pub fn ok(body: String) -> Response {
  Response(200, dict.new(), body)
}

pub fn text(status status: Int, body body: String) -> Response {
  let headers = dict.new() |> dict.insert("content-type", "text/plain; charset=utf-8")
  Response(status, headers, body)
}

pub fn json(status status: Int, body body: String) -> Response {
  let headers = dict.new() |> dict.insert("content-type", "application/json")
  Response(status, headers, body)
}

fn default_not_found(_request: Request) -> Response {
  text(status: 404, body: "Not Found")
}

fn run_middlewares(middlewares: List(Middleware), request: Request, endpoint: Handler) -> Response {
  case middlewares {
    [] -> endpoint(request)
    [first, ..rest] -> {
      let next = fn(req: Request) { run_middlewares(rest, req, endpoint) }
      first(request, next)
    }
  }
}

fn find_route(
  routes: List(Route),
  request: Request,
) -> Result(#(List(Middleware), Handler, Request), Nil) {
  case routes {
    [] -> Error(Nil)
    [route, ..rest] ->
      case match_route(route, request) {
        Ok(found) -> Ok(found)
        Error(Nil) -> find_route(rest, request)
      }
  }
}

fn match_route(route: Route, request: Request) -> Result(#(List(Middleware), Handler, Request), Nil) {
  let Route(methods, _, segments, middlewares, handler) = route
  let Request(request_method, path, headers, query, _, body) = request

  case list.any(methods, fn(m) { m == request_method }) {
    False -> Error(Nil)
    True ->
      case match_segments(segments, split_path(path), dict.new()) {
        Error(Nil) -> Error(Nil)
        Ok(params) ->
          Ok(#(middlewares, handler, Request(request_method, path, headers, query, params, body)))
      }
  }
}

fn parse_pattern(pattern: String) -> List(Segment) {
  split_path(pattern)
  |> list.map(fn(part) {
    case string.starts_with(part, ":") {
      True -> Param(string.drop_left(part, 1))
      False -> Static(part)
    }
  })
}

fn split_path(path: String) -> List(String) {
  path
  |> string.split("/")
  |> list.filter(fn(part) { part != "" })
}

fn match_segments(
  pattern_segments: List(Segment),
  path_segments: List(String),
  params: dict.Dict(String, String),
) -> Result(dict.Dict(String, String), Nil) {
  case pattern_segments, path_segments {
    [], [] -> Ok(params)
    [Static(expected), ..pattern_rest], [current, ..path_rest] ->
      case expected == current {
        True -> match_segments(pattern_rest, path_rest, params)
        False -> Error(Nil)
      }
    [Param(name), ..pattern_rest], [current, ..path_rest] -> {
      let updated = dict.insert(params, name, current)
      match_segments(pattern_rest, path_rest, updated)
    }
    _, _ -> Error(Nil)
  }
}
