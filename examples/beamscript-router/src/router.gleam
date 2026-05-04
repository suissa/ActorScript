import gleam/dict
import gleam/list
import gleam/string

pub type Method {
  Get
  Post
  Put
  Patch
  Delete
  Options
  Head
  Any
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
  Wildcard(String)
}

pub type Route {
  Route(method: Method, pattern: String, segments: List(Segment), handler: Handler)
}

pub type Router {
  Router(routes: List(Route), middlewares: List(Middleware), not_found: Handler)
}

pub fn new() -> Router {
  Router([], [], default_not_found)
}

pub fn with_not_found(router: Router, handler: Handler) -> Router {
  let Router(routes, middlewares, _) = router
  Router(routes, middlewares, handler)
}

pub fn use(router: Router, middleware: Middleware) -> Router {
  let Router(routes, middlewares, not_found) = router
  Router(routes, list.append(middlewares, [middleware]), not_found)
}

pub fn get(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Get, pattern, handler)
}

pub fn post(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Post, pattern, handler)
}

pub fn put(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Put, pattern, handler)
}

pub fn patch(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Patch, pattern, handler)
}

pub fn delete(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Delete, pattern, handler)
}

pub fn options(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Options, pattern, handler)
}

pub fn head(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Head, pattern, handler)
}

pub fn all(router: Router, pattern: String, handler: Handler) -> Router {
  route(router, Any, pattern, handler)
}

pub fn route(router: Router, method: Method, pattern: String, handler: Handler) -> Router {
  let Router(routes, middlewares, not_found) = router
  let segments = parse_pattern(pattern)
  let entry = Route(method, pattern, segments, handler)
  Router(list.append(routes, [entry]), middlewares, not_found)
}

pub fn handle(router: Router, request: Request) -> Response {
  let Router(routes, middlewares, not_found) = router

  case find_route(routes, request) {
    Ok(tuple(handler, with_params)) ->
      run_middlewares(middlewares, with_params, handler)

    Error(Nil) ->
      run_middlewares(middlewares, request, not_found)
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

fn run_middlewares(
  middlewares: List(Middleware),
  request: Request,
  endpoint: Handler,
) -> Response {
  case middlewares {
    [] -> endpoint(request)
    [first, ..rest] -> {
      let next = fn(req: Request) { run_middlewares(rest, req, endpoint) }
      first(request, next)
    }
  }
}

fn find_route(routes: List(Route), request: Request) -> Result(#(Handler, Request), Nil) {
  case routes {
    [] -> Error(Nil)
    [route, ..rest] ->
      case match_route(route, request) {
        Ok(found) -> Ok(found)
        Error(Nil) -> find_route(rest, request)
      }
  }
}

fn match_route(route: Route, request: Request) -> Result(#(Handler, Request), Nil) {
  let Route(route_method, _, segments, handler) = route
  let Request(request_method, path, headers, query, _, body) = request

  case method_matches(route_method, request_method) {
    False -> Error(Nil)
    True ->
      case match_segments(segments, split_path(path), dict.new()) {
        Error(Nil) -> Error(Nil)
        Ok(params) -> Ok(#(handler, Request(request_method, path, headers, query, params, body)))
      }
  }
}

fn method_matches(route_method: Method, request_method: Method) -> Bool {
  case route_method {
    Any -> True
    _ -> route_method == request_method
  }
}

fn parse_pattern(pattern: String) -> List(Segment) {
  split_path(pattern)
  |> list.map(fn(part) {
    case string.starts_with(part, ":") {
      True -> Param(string.drop_left(part, 1))
      False ->
        case string.starts_with(part, "*") {
          True -> Wildcard(string.drop_left(part, 1))
          False -> Static(part)
        }
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
    [Wildcard(name)], rest -> Ok(dict.insert(params, name, string.join(rest, "/")))
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
