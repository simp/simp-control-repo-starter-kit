#
plan ctlrepo::lint_gitlab_ci (
  TargetSpec           $targets     = 'localhost',
  Stdlib::Absolutepath $file        = "${system::env('PWD')}/.gitlab-ci.yml",
  Stdlib::Host         $server      = lookup('gitlab_url', { 'default_value' => 'gitlab.com' }),
  Stdlib::HTTPUrl      $ci_lint_api = "https://${server}/api/v4/ci/lint",
  Sensitive[String[1]] $token       = Sensitive(system::env('GITLAB_API_TOKEN')),
){
  unless file::exists($file) { fail_plan("Cannot find $file") }

  return run_task('ctlrepo::lint_gitlab_ci', get_targets($targets), "CI Lint: $file", {
    'gitlab_ci_lint_uri'       => $ci_lint_api,
    'gitlab_private_api_token' => "${token.unwrap}",
    'repo_paths' => [$file.dirname],
  })
}
