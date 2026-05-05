# BEAMScript Router (Express-like)

Módulo HTTP de rotas inspirado em **Express**, com interface funcional e contexto encapsulado.

## Interface desejada

Sem `obj.method()`, a API mapeia os métodos HTTP para funções com a assinatura:

- `get(rota, [middlewares], handler)`
- `post(rota, [middlewares], handler)`
- `put(rota, [middlewares], handler)`
- `patch(rota, [middlewares], handler)`
- `delete(rota, [middlewares], handler)`

## Contexto encapsulado

`HttpContext` encapsula o `Router` e expõe os métodos HTTP como funções acessíveis via contexto.

```gleam
let ctx0 = router.context()
let router.HttpContext(_, get, post, put, patch, delete) = ctx0

let ctx1 = get("/users/:id", [auth], get_user)
let ctx2 = post("/users", [auth], create_user)
let ctx3 = put("/users/:id", [auth], replace_user)
let ctx4 = patch("/users/:id", [auth], patch_user)
let ctx5 = delete("/users/:id", [auth], delete_user)

let app = router.unwrap(ctx5)
```

## Cobertura de testes

- **Unitários**: parsing de params e bloqueio de sessão.
- **BDD**: cenários Given/When/Then para sessão válida/inválida.
- **E2E**: fluxo completo CRUD de users com middleware de sessão.

Arquivos de teste:
- `test/router_unit_test.gleam`
- `test/router_bdd_test.gleam`
- `test/router_e2e_test.gleam`
