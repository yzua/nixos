# GitHub personal activity widgets for Glance dashboard.
# Requires GITHUB_TOKEN via environmentFile (sops template).

{
  notifications = {
    type = "custom-api";
    title = "Notifications";
    cache = "30m";
    url = "https://api.github.com/notifications?all=false&per_page=15";
    headers = {
      Authorization = "Bearer \${GITHUB_TOKEN}";
      Accept = "application/vnd.github+json";
    };
    template = ''
      <ul class="list list-gap-10 collapsible-container" data-collapse-after="5">
        {{ range .JSON.Array "" }}
          <li>
            <div class="flex items-center gap-5">
              {{ if eq .String "reason" "assign" }}<span class="color-positive">A</span>
              {{ else if eq .String "reason" "mention" }}<span class="color-highlight">@</span>
              {{ else if eq .String "reason" "review_requested" }}<span class="color-primary">R</span>
              {{ else if eq .String "reason" "subscribed" }}<span class="color-subdue">S</span>
              {{ else }}<span class="color-subdue">&bull;</span>
              {{ end }}
              <a class="color-primary-if-not-visited" href="{{ .String "subject.url" | replaceAll "api.github.com/repos" "github.com" | replaceAll "/pulls/" "/pull/" }}">{{ .String "subject.title" }}</a>
            </div>
            <div class="color-subdue text-small">{{ .String "repository.full_name" }}</div>
          </li>
        {{ else }}
          <li class="color-subdue">No new notifications</li>
        {{ end }}
      </ul>
    '';
  };

  personalRepos = {
    type = "custom-api";
    title = "My Repos";
    cache = "30m";
    url = "https://api.github.com/user/repos?affiliation=owner&sort=updated&per_page=10";
    headers = {
      Authorization = "Bearer \${GITHUB_TOKEN}";
      Accept = "application/vnd.github.v3+json";
    };
    template = ''
      <ul class="list list-gap-10 collapsible-container" data-collapse-after="5">
        {{ range .JSON.Array "" }}
          <li>
            <div class="flex items-center justify-between">
              <a class="color-primary-if-not-visited" href="{{ .String "html_url" }}">{{ .String "name" }}</a>
              <ul class="list-horizontal-text">
                <li class="text-small color-subdue">{{ .String "language" }}</li>
                <li class="text-small color-subdue">&#9733; {{ .Int "stargazers_count" }}</li>
              </ul>
            </div>
            <div class="color-subdue text-small margin-top-2">{{ .String "description" }}</div>
          </li>
        {{ end }}
      </ul>
    '';
  };
}
