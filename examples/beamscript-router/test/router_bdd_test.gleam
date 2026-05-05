import app
import gleeunit/should
import router

pub fn bdd_given_valid_session_when_get_user_then_returns_200() {
  let router.Response(status, _, body) =
    app.dispatch(router.Get, "/users/1", "valid-session")

  should.equal(status, 200)
  should.equal(body, "{\"action\":\"get\",\"id\":\"1\"}")
}

pub fn bdd_given_invalid_session_when_get_user_then_returns_401() {
  let router.Response(status, _, body) =
    app.dispatch(router.Get, "/users/1", "")

  should.equal(status, 401)
  should.equal(body, "Unauthorized")
}
