# BEAMScript Router (Express/Fastify-like)

Framework de rotas minimalista inspirado em **Express** e **Fastify**, com API funcional e imutável:

- `router.get/post/put/patch/delete/head/options/all`
- parâmetros de rota (`/users/:id`)
- wildcard (`/assets/*path`)
- middleware (`router.use`)
- fallback 404 customizável (`router.with_not_found`)

## Exemplo

```gleam
import gleam/dict
import router

pub fn app() -> router.Router {
  router.new()
  |> router.use(request_logger)
  |> router.get("/", fn(_req) { router.ok("hello") })
  |> router.get("/users/:id", user_by_id)
}

pub fn dispatch(method: router.Method, path: String) -> router.Response {
  let req = router.Request(method, path, dict.new(), dict.new(), dict.new(), "")
  router.handle(app(), req)
}
```

## Arquivos

- `src/router.gleam`: núcleo do framework.
- `src/app.gleam`: app de exemplo.
