# GitHub trending repositories widget for Glance dashboard.
# Uses OSSInsight public API — no authentication required.

{
  type = "custom-api";
  title = "Trending Repos";
  cache = "24h";
  url = "https://api.ossinsight.io/v1/trends/repos/?period=past_24_hours&language=All";
  template = ''
    <ul class="list list-gap-10 collapsible-container" data-collapse-after="3">
      {{ range .JSON.Array "data.rows" }}
        <li>
          <a class="color-primary-if-not-visited" href="https://github.com/{{ .String "repo_name" }}">{{ .String "repo_name" }}</a>
          <ul class="list-horizontal-text">
            <li class="color-highlight">{{ .String "primary_language" }}</li>
            <li>{{ .String "stars" }} stars</li>
            <li>{{ .String "forks" }} forks</li>
          </ul>
          <ul class="list collapsible-container">
            <li class="color-subdue">{{ .String "description" }}</li>
          </ul>
        </li>
      {{ end }}
    </ul>
  '';
}
