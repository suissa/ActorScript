import app
import gleeunit/should
import router

pub fn e2e_users_crud_with_session_validation() {
  let router.Response(get_status, _, get_body) =
    app.dispatch(router.Get, "/users/7", "valid-session")
  should.equal(get_status, 200)
  should.equal(get_body, "{\"action\":\"get\",\"id\":\"7\"}")

  let router.Response(post_status, _, post_body) =
    app.dispatch(router.Post, "/users", "valid-session")
  should.equal(post_status, 201)
  should.equal(post_body, "{\"action\":\"create\"}")

  let router.Response(put_status, _, put_body) =
    app.dispatch(router.Put, "/users/7", "valid-session")
  should.equal(put_status, 200)
  should.equal(put_body, "{\"action\":\"replace\",\"id\":\"7\"}")

  let router.Response(patch_status, _, patch_body) =
    app.dispatch(router.Patch, "/users/7", "valid-session")
  should.equal(patch_status, 200)
  should.equal(patch_body, "{\"action\":\"patch\",\"id\":\"7\"}")

  let router.Response(delete_status, _, delete_body) =
    app.dispatch(router.Delete, "/users/7", "valid-session")
  should.equal(delete_status, 200)
  should.equal(delete_body, "{\"action\":\"delete\",\"id\":\"7\"}")

  let router.Response(unauth_status, _, unauth_body) =
    app.dispatch(router.Delete, "/users/7", "bad")
  should.equal(unauth_status, 401)
  should.equal(unauth_body, "Unauthorized")
}
