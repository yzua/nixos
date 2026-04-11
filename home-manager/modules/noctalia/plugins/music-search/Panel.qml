import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "MusicUtils.js" as MusicUtils

Item {
  id: root

  property var pluginApi: null

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property var geometryPlaceholder: panelContainer
  readonly property string helperPath: mainInstance?.helperPath || Qt.resolvedUrl("musicctl.sh").toString().replace("file://", "")
  readonly property string commandName: ">" + (pluginApi?.manifest?.metadata?.commandPrefix || "music-search")
  readonly property bool hasPlayback: mainInstance?.isPlaying === true || mainInstance?.playbackStarting === true
  readonly property var filteredLibraryEntries: buildFilteredLibraryEntries()
  readonly property var filteredPlaylistEntries: buildFilteredPlaylistEntries()
  readonly property var filteredArtistStats: buildFilteredArtistStats()
  readonly property var filteredTagStats: buildFilteredTagStats()
  readonly property var recentLibraryEntries: buildRecentLibraryEntries()
  readonly property var activeLibrarySelectionList: activeLibrarySelectionEntries()
  readonly property var activeLibraryTrackList: hasLibrarySelection()
      ? activeLibrarySelectionList
      : (librarySection === "tracks" ? filteredLibraryEntries : [])
  readonly property string defaultPanelTab: {
    var value = (pluginApi?.pluginSettings?.defaultPanelTab
                 ?? defaults.defaultPanelTab
                 ?? "search");
    value = value.trim().toLowerCase();
    if (value === "library" || value === "queue") {
      return value;
    }
    return "search";
  }
  readonly property string defaultPanelLibrarySection: {
    var value = (pluginApi?.pluginSettings?.defaultPanelLibrarySection
                 ?? defaults.defaultPanelLibrarySection
                 ?? "tracks");
    value = value.trim().toLowerCase();
    if (value === "playlists" || value === "artists" || value === "tags") {
      return value;
    }
    return "tracks";
  }
  readonly property string panelDensity: {
    var value = (pluginApi?.pluginSettings?.panelDensity
                 ?? defaults.panelDensity
                 ?? "balanced");
    value = value.trim().toLowerCase();
    if (value === "compact" || value === "roomy") {
      return value;
    }
    return "balanced";
  }
  readonly property bool showPanelHeader: pluginApi?.pluginSettings?.showPanelHeader
      ?? defaults.showPanelHeader
      ?? true
  readonly property real panelSectionSpacing: panelDensity === "compact"
      ? Style.marginS
      : (panelDensity === "roomy" ? Style.marginL : Style.marginM)
  readonly property real panelCardPadding: panelDensity === "compact"
      ? Style.marginL
      : (panelDensity === "roomy" ? Style.marginXL : Style.marginL)
  readonly property real panelCardSpacing: panelDensity === "compact"
      ? Style.marginXS
      : (panelDensity === "roomy" ? Style.marginM : Style.marginS)
  readonly property real panelCardHeaderSpacing: panelDensity === "compact"
      ? Style.marginS
      : (panelDensity === "roomy" ? Style.marginL : Style.marginM)
  readonly property real panelCardRadius: panelDensity === "compact"
      ? Style.radiusM
      : (panelDensity === "roomy" ? (Style.radiusL + Style.marginXS) : Style.radiusL)
  readonly property real panelTitleSize: panelDensity === "compact"
      ? Style.fontSizeS
      : (panelDensity === "roomy" ? Style.fontSizeL : Style.fontSizeM)
  readonly property real panelBodySize: panelDensity === "compact"
      ? Style.fontSizeXS
      : (panelDensity === "roomy" ? Style.fontSizeM : Style.fontSizeS)
  readonly property real panelButtonSize: panelDensity === "compact"
      ? Style.fontSizeXS
      : (panelDensity === "roomy" ? Style.fontSizeM : Style.fontSizeS)
  readonly property real panelBadgeSize: panelDensity === "compact"
      ? Style.fontSizeXS
      : (panelDensity === "roomy" ? Style.fontSizeS : Style.fontSizeXS)
  readonly property bool showPanelNowPlaying: pluginApi?.pluginSettings?.showPanelNowPlaying
      ?? defaults.showPanelNowPlaying
      ?? true
  readonly property bool showPanelPlaybackProgress: pluginApi?.pluginSettings?.showPanelPlaybackProgress
      ?? defaults.showPanelPlaybackProgress
      ?? true
  readonly property bool showPanelProviderChips: pluginApi?.pluginSettings?.showPanelProviderChips
      ?? defaults.showPanelProviderChips
      ?? true
  readonly property bool showPanelRecentTracks: pluginApi?.pluginSettings?.showPanelRecentTracks
      ?? defaults.showPanelRecentTracks
      ?? true
  readonly property bool showPanelSearchHelper: pluginApi?.pluginSettings?.showPanelSearchHelper
      ?? defaults.showPanelSearchHelper
      ?? true
  readonly property bool showPanelPreview: pluginApi?.pluginSettings?.showPanelPreview
      ?? defaults.showPanelPreview
      ?? true
  readonly property bool showPanelUrlActions: pluginApi?.pluginSettings?.showPanelUrlActions
      ?? defaults.showPanelUrlActions
      ?? true
  readonly property bool showPanelSpeedControls: pluginApi?.pluginSettings?.showPanelSpeedControls
      ?? defaults.showPanelSpeedControls
      ?? true
  readonly property bool showPanelQueueControls: pluginApi?.pluginSettings?.showPanelQueueControls
      ?? defaults.showPanelQueueControls
      ?? true
  readonly property bool showPanelStatusBanner: pluginApi?.pluginSettings?.showPanelStatusBanner
      ?? defaults.showPanelStatusBanner
      ?? true
  readonly property real previewPaneMinWidth: Math.round(240 * Style.uiScaleRatio)
  readonly property real previewPaneMaxWidthCap: Math.round(420 * Style.uiScaleRatio)

  property real contentPreferredWidth: 820 * Style.uiScaleRatio
  property real contentPreferredHeight: 820 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  property string activeTab: "search"
  property string librarySection: "tracks"
  property string searchText: ""
  property string libraryFilterText: ""
  property string selectedPlaylistId: ""
  property string selectedArtistName: ""
  property string selectedTagName: ""
  property var searchResults: []
  property string searchError: ""
  property bool searchBusy: false
  property string activeSearchQuery: ""
  property string pendingSearchQuery: ""
  property string lastCompletedQuery: ""
  property string runningSearchQuery: ""
  property string runningSearchProvider: ""
  property int searchEpoch: 0
  property int runningSearchEpoch: 0
  property bool pendingSearchRestart: false
  property bool seekDragging: false
  property real localSeekRatio: -1
  property var previewDetailCache: ({})
  property var panelPreviewItem: null
  property bool panelPreviewFollowsPlayback: true
  property bool panelPreviewDismissed: false
  property real previewPaneWidth: 0
  property real preferredPreviewPaneWidth: 0

  anchors.fill: parent

  Process {
    id: searchProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      var completedQuery = root.runningSearchQuery;
      var staleSearch = root.runningSearchEpoch !== root.searchEpoch;

      root.searchBusy = false;
      root.searchError = "";

      if (!staleSearch && exitCode === 0) {
        try {
          var parsed = JSON.parse(searchProcess.stdout.text || "[]");
          root.searchResults = Array.isArray(parsed) ? parsed : [];
          root.lastCompletedQuery = completedQuery;
        } catch (error) {
          root.searchResults = [];
          root.lastCompletedQuery = completedQuery;
          root.searchError = pluginApi?.tr("errors.searchMalformed");
        }
      } else if (!staleSearch) {
        root.searchResults = [];
        root.lastCompletedQuery = completedQuery;
        root.searchError = (searchProcess.stderr.text || "").trim() || pluginApi?.tr("search.failed");
      }

      root.runningSearchQuery = "";
      root.runningSearchProvider = "";

      if (root.pendingSearchQuery && (root.pendingSearchRestart || root.pendingSearchQuery !== completedQuery)) {
        var nextQuery = root.pendingSearchQuery;
        root.pendingSearchQuery = "";
        root.pendingSearchRestart = false;
        root.startSearch(nextQuery);
      }
    }
  }

  Timer {
    id: searchDelay
    interval: 250
    repeat: false
    onTriggered: root.performSearch()
  }

  Connections {
    target: mainInstance
    ignoreUnknownSignals: true

    function onCurrentProviderChanged() {
      root.searchEpoch += 1;
      root.searchResults = [];
      root.lastCompletedQuery = "";
      root.searchError = "";

      if (root.searchBusy && root.trimmedSearchText().length > 0) {
        if (root.pendingSearchQuery.length === 0) {
          root.pendingSearchQuery = root.trimmedSearchText();
        }
        root.pendingSearchRestart = true;
      } else if (root.activeTab === "search" && root.trimmedSearchText().length > 0 && !root.looksLikeUrl(root.trimmedSearchText())) {
        searchDelay.restart();
      }
    }

    function onIsPlayingChanged() {
      root.syncPanelPlaybackPreview(false);
    }

    function onPlaybackStartingChanged() {
      root.syncPanelPlaybackPreview(false);
    }

    function onCurrentEntryIdChanged() {
      root.syncPanelPlaybackPreview(false);
    }

    function onCurrentUrlChanged() {
      root.syncPanelPlaybackPreview(false);
    }

    function onCurrentTitleChanged() {
      root.syncPanelPlaybackPreview(false);
    }

    function onCurrentUploaderChanged() {
      root.syncPanelPlaybackPreview(false);
    }

    function onCurrentDurationChanged() {
      root.syncPanelPlaybackPreview(false);
    }
  }

  onVisibleChanged: {
    if (visible) {
      activeTab = defaultPanelTab;
      setLibrarySection(defaultPanelLibrarySection);
      syncPanelPlaybackPreview(true);
      mainInstance?.refreshStatus(true);
      Qt.callLater(root.focusCurrentInput);
    }
  }

  onShowPanelPreviewChanged: {
    if (showPanelPreview && visible) {
      syncPanelPlaybackPreview(true);
      ensurePreviewPaneWidth(true);
    }
  }

  onPanelPreviewItemChanged: {
    if (panelPreviewItem) {
      ensurePreviewPaneWidth(false);
    }
  }

  onActiveTabChanged: {
    if (visible) {
      Qt.callLater(root.focusCurrentInput);
    }
  }

  function focusCurrentInput() {
    if (activeTab === "search") {
      if (searchInput.inputItem) {
        searchInput.inputItem.forceActiveFocus();
      } else {
        searchInput.forceActiveFocus();
      }
      return;
    }

    if (activeTab === "library") {
      if (libraryFilterInput.inputItem) {
        libraryFilterInput.inputItem.forceActiveFocus();
      } else {
        libraryFilterInput.forceActiveFocus();
      }
    }
  }

  function trimmedSearchText() {
    return (searchText || "").trim();
  }

  function providerLabel(provider) {
    return mainInstance?.providerLabel(provider)
        || (provider === "soundcloud"
            ? pluginApi?.tr("providers.soundcloud")
            : (provider === "local"
                ? pluginApi?.tr("providers.local")
                : pluginApi?.tr("providers.youtube")));
  }

  function looksLikeUrl(value) {
    var trimmed = (value || "").trim();
    return /^[a-z][a-z0-9+.-]*:\/\//i.test(trimmed) || /^www\./i.test(trimmed);
  }

  function parseSearchProviderQuery(query) {
    var raw = query || "";
    var match = raw.match(/^(yt|youtube|sc|soundcloud|local):\s*(.*)$/i);
    if (!match) {
      return {
        "provider": mainInstance?.currentProvider || "youtube",
        "query": raw
      };
    }

    var prefix = (match[1] || "").toLowerCase();
    var provider = "youtube";
    if (prefix === "sc" || prefix === "soundcloud") {
      provider = "soundcloud";
    } else if (prefix === "local") {
      provider = "local";
    }

    return {
      "provider": provider,
      "query": (match[2] || "").trim()
    };
  }

  function performSearch(forceImmediate) {
    var query = trimmedSearchText();

    if (looksLikeUrl(query) || query.length === 0) {
      searchEpoch += 1;
      searchResults = [];
      searchError = "";
      activeSearchQuery = "";
      pendingSearchQuery = "";
      pendingSearchRestart = false;
      lastCompletedQuery = "";
      return;
    }

    var parsed = parseSearchProviderQuery(query);
    var resolvedQuery = (parsed.query || "").trim();
    if (resolvedQuery.length < 2) {
      searchEpoch += 1;
      searchResults = [];
      searchError = "";
      activeSearchQuery = query;
      pendingSearchQuery = "";
      pendingSearchRestart = false;
      return;
    }

    if (forceImmediate === true) {
      if (searchBusy) {
        pendingSearchQuery = query;
        pendingSearchRestart = true;
        return;
      }
      startSearch(query);
      return;
    }

    if (searchBusy) {
      pendingSearchQuery = query;
      return;
    }

    startSearch(query);
  }

  function startSearch(query) {
    if (!helperPath) {
      return;
    }

    var parsed = parseSearchProviderQuery(query);
    var provider = parsed.provider;
    var resolvedQuery = (parsed.query || "").trim();

    if (resolvedQuery.length < 2) {
      searchResults = [];
      searchError = "";
      return;
    }

    activeSearchQuery = query;
    pendingSearchQuery = "";
    pendingSearchRestart = false;
    searchBusy = true;
    searchError = "";
    runningSearchQuery = query;
    runningSearchProvider = provider;
    runningSearchEpoch = searchEpoch;
    searchProcess.exec({
                         "command": ["bash", helperPath, "search", resolvedQuery, provider]
                       });
  }

  function normalizedEntry(entry) {
    return {
      "id": entry?.id || "",
      "title": entry?.title || entry?.name || pluginApi?.tr("common.untitled"),
      "url": entry?.url || "",
      "uploader": entry?.uploader || "",
      "duration": entry?.duration || 0,
      "provider": entry?.provider || "",
      "album": entry?.album || "",
      "tags": Array.isArray(entry?.tags) ? entry.tags : [],
      "rating": entry?.rating || 0,
      "playCount": entry?.playCount || 0,
      "savedAt": entry?.savedAt || "",
      "lastPlayedAt": entry?.lastPlayedAt || "",
      "queuedAt": entry?.queuedAt || ""
    };
  }

  function compareIsoStringsDesc(a, b) {
    var aValue = a || "";
    var bValue = b || "";
    if (aValue === bValue) {
      return 0;
    }
    return aValue > bValue ? -1 : 1;
  }

  function buildFilteredLibraryEntries() {
    var entries = sortLibraryEntries((mainInstance?.visibleLibraryEntries() || []).slice());
    var query = (libraryFilterText || "").trim().toLowerCase();

    if (query.length === 0) {
      return entries;
    }

    return entries.filter(function (entry) {
      var haystack = [
        entry?.title || "",
        entry?.uploader || "",
        entry?.album || "",
        (entry?.tags || []).join(" ") || ""
      ].join(" ").toLowerCase();
      return haystack.indexOf(query) >= 0;
    });
  }

  function sortLibraryEntries(entries) {
    var mode = mainInstance?.currentSortBy || "date";

    entries.sort(function (left, right) {
      if (mode === "title") {
        return (left?.title || "").localeCompare(right?.title || "");
      }
      if (mode === "duration") {
        return (right?.duration || 0) - (left?.duration || 0);
      }
      if (mode === "rating") {
        var ratingDiff = (right?.rating || 0) - (left?.rating || 0);
        if (ratingDiff !== 0) {
          return ratingDiff;
        }
      }
      return compareIsoStringsDesc(left?.savedAt, right?.savedAt);
    });

    return entries;
  }

  function buildFilteredPlaylistEntries() {
    var playlists = (mainInstance?.playlistEntries || []).slice();
    var query = (libraryFilterText || "").trim().toLowerCase();

    playlists.sort(function (left, right) {
      var leftDate = left?.createdAt || "";
      var rightDate = right?.createdAt || "";
      if (leftDate !== rightDate) {
        return compareIsoStringsDesc(leftDate, rightDate);
      }
      return (left?.name || "").localeCompare(right?.name || "");
    });

    if (query.length === 0) {
      return playlists;
    }

    return playlists.filter(function (playlist) {
      var haystack = [
        playlist?.name || "",
        playlist?.sourceFolder || ""
      ].join(" ").toLowerCase();
      return haystack.indexOf(query) >= 0;
    });
  }

  function collectArtistStats() {
    var seen = ({});
    var stats = [];
    var library = mainInstance?.visibleLibraryEntries() || [];

    for (var i = 0; i < library.length; i++) {
      var artist = (library[i].uploader || "").trim();
      var key = artist.toLowerCase();
      if (key.length === 0) {
        continue;
      }
      if (!seen[key]) {
        seen[key] = {
          "name": artist,
          "count": 0,
          "playCount": 0,
          "lastPlayedAt": ""
        };
        stats.push(seen[key]);
      }
      seen[key].count += 1;
      seen[key].playCount += Number(library[i].playCount || 0);
      var playedAt = (library[i].lastPlayedAt || "");
      if (playedAt.length > 0 && playedAt > seen[key].lastPlayedAt) {
        seen[key].lastPlayedAt = playedAt;
      }
    }

    stats.sort(function (a, b) {
      if (b.count !== a.count) {
        return b.count - a.count;
      }
      if (b.playCount !== a.playCount) {
        return b.playCount - a.playCount;
      }
      return a.name.localeCompare(b.name);
    });
    return stats;
  }

  function normalizeTagValue(tag) {
    var value = String(tag || "").trim();
    return value.replace(/^#+/, "");
  }

  function collectTagStats() {
    var seen = ({});
    var stats = [];
    var library = mainInstance?.visibleLibraryEntries() || [];

    for (var i = 0; i < library.length; i++) {
      var entryTags = library[i].tags || [];
      for (var j = 0; j < entryTags.length; j++) {
        var normalizedTag = normalizeTagValue(entryTags[j]);
        var key = normalizedTag.toLowerCase();
        if (key.length === 0) {
          continue;
        }
        if (!seen[key]) {
          seen[key] = {
            "tag": normalizedTag,
            "count": 0
          };
          stats.push(seen[key]);
        }
        seen[key].count += 1;
      }
    }

    stats.sort(function (a, b) {
      if (b.count !== a.count) {
        return b.count - a.count;
      }
      return a.tag.localeCompare(b.tag);
    });
    return stats;
  }

  function buildFilteredArtistStats() {
    var artists = collectArtistStats();
    var query = (libraryFilterText || "").trim().toLowerCase();
    if (query.length === 0) {
      return artists;
    }

    return artists.filter(function (artist) {
      return (artist?.name || "").toLowerCase().indexOf(query) >= 0;
    });
  }

  function buildFilteredTagStats() {
    var tags = collectTagStats();
    var query = normalizeTagValue(libraryFilterText).toLowerCase();
    if (query.length === 0) {
      return tags;
    }

    return tags.filter(function (tagStat) {
      return (tagStat?.tag || "").toLowerCase().indexOf(query) >= 0;
    });
  }

  function resolvePlaylistEntry(playlist) {
    var playlistId = String(playlist?.id || "").trim();
    if (playlistId.length > 0) {
      var resolved = mainInstance?.findPlaylistById(playlistId);
      if (resolved) {
        return resolved;
      }
    }
    return playlist || null;
  }

  function playlistEntryCount(playlist) {
    var resolved = resolvePlaylistEntry(playlist);
    return Array.isArray(resolved?.entryIds) ? resolved.entryIds.length : 0;
  }

  function playlistDetailEntries(playlistId) {
    var targetId = String(playlistId || "").trim();
    if (targetId.length === 0) {
      return [];
    }

    var targetPlaylist = resolvePlaylistEntry({"id": targetId});

    if (!targetPlaylist) {
      return [];
    }

    var library = mainInstance?.libraryEntries || [];
    var tracks = [];
    var entryIds = targetPlaylist.entryIds || [];
    for (var j = 0; j < entryIds.length; j++) {
      var entryId = String(entryIds[j] || "");
      for (var k = 0; k < library.length; k++) {
        if (String(library[k]?.id || "") === entryId) {
          tracks.push(library[k]);
          break;
        }
      }
    }

    return sortLibraryEntries(tracks);
  }

  function artistDetailEntries(artistName) {
    var target = (artistName || "").trim().toLowerCase();
    if (target.length === 0) {
      return [];
    }

    return sortLibraryEntries((mainInstance?.visibleLibraryEntries() || []).filter(function (entry) {
      return (entry?.uploader || "").trim().toLowerCase() === target;
    }).slice());
  }

  function tagDetailEntries(tagName) {
    var target = normalizeTagValue(tagName).toLowerCase();
    if (target.length === 0) {
      return [];
    }

    return sortLibraryEntries((mainInstance?.visibleLibraryEntries() || []).filter(function (entry) {
      var tags = Array.isArray(entry?.tags) ? entry.tags : [];
      for (var i = 0; i < tags.length; i++) {
        if (normalizeTagValue(tags[i]).toLowerCase() === target) {
          return true;
        }
      }
      return false;
    }).slice());
  }

  function buildRecentLibraryEntries() {
    var entries = (mainInstance?.visibleLibraryEntries() || []).slice();
    entries.sort(function (left, right) {
      var leftDate = left?.lastPlayedAt || left?.savedAt || "";
      var rightDate = right?.lastPlayedAt || right?.savedAt || "";
      return compareIsoStringsDesc(leftDate, rightDate);
    });
    return entries.slice(0, 10);
  }

  function librarySectionLabel(section) {
    if (section === "playlists") {
      return pluginApi?.tr("panel.playlists");
    }
    if (section === "artists") {
      return pluginApi?.tr("panel.artists");
    }
    if (section === "tags") {
      return pluginApi?.tr("panel.tags");
    }
    return pluginApi?.tr("panel.tracks");
  }

  function libraryPlaceholderText() {
    if (librarySection === "playlists") {
      return pluginApi?.tr("panel.playlistsPlaceholder");
    }
    if (librarySection === "artists") {
      return pluginApi?.tr("panel.artistsPlaceholder");
    }
    if (librarySection === "tags") {
      return pluginApi?.tr("panel.tagsPlaceholder");
    }
    return pluginApi?.tr("panel.libraryPlaceholder");
  }

  function setLibrarySection(section) {
    librarySection = section || "tracks";
    selectedPlaylistId = "";
    selectedArtistName = "";
    selectedTagName = "";
    libraryFilterText = "";
  }

  function hasLibrarySelection() {
    return selectedPlaylistId.length > 0 || selectedArtistName.length > 0 || selectedTagName.length > 0;
  }

  function activeLibrarySelectionTitle() {
    if (selectedPlaylistId.length > 0) {
      var playlist = mainInstance?.findPlaylistById(selectedPlaylistId);
      return playlist?.name || pluginApi?.tr("panel.playlists");
    }
    if (selectedArtistName.length > 0) {
      return selectedArtistName;
    }
    if (selectedTagName.length > 0) {
      return "#" + selectedTagName;
    }
    return "";
  }

  function activeLibrarySelectionEntries() {
    if (selectedPlaylistId.length > 0) {
      return playlistDetailEntries(selectedPlaylistId);
    }
    if (selectedArtistName.length > 0) {
      return artistDetailEntries(selectedArtistName);
    }
    if (selectedTagName.length > 0) {
      return tagDetailEntries(selectedTagName);
    }
    return [];
  }

  function openPlaylistSection(playlistId) {
    selectedPlaylistId = String(playlistId || "").trim();
    selectedArtistName = "";
    selectedTagName = "";
  }

  function openArtistSection(artistName) {
    selectedArtistName = String(artistName || "").trim();
    selectedPlaylistId = "";
    selectedTagName = "";
  }

  function openTagSection(tagName) {
    selectedTagName = normalizeTagValue(tagName);
    selectedPlaylistId = "";
    selectedArtistName = "";
  }

  function clearLibrarySelection() {
    selectedPlaylistId = "";
    selectedArtistName = "";
    selectedTagName = "";
  }

  function currentLibraryActionEntries(shuffle) {
    var entries = activeLibrarySelectionList.slice();
    return shuffle === true ? (mainInstance?.shuffleEntries(entries) || entries) : entries;
  }

  function playCurrentLibrarySelection(shuffle) {
    var entries = currentLibraryActionEntries(shuffle);
    mainInstance?.startQueueBatch(entries, {
                                    "clearFirst": true,
                                    "finalAction": "skip",
                                    "emptyNotice": pluginApi?.tr("panel.emptyScopedLibrary")
                                  });
  }

  function queueCurrentLibrarySelection(shuffle) {
    var entries = currentLibraryActionEntries(shuffle);
    mainInstance?.startQueueBatch(entries, {
                                    "clearFirst": false,
                                    "emptyNotice": pluginApi?.tr("panel.emptyScopedLibrary")
                                  });
  }

  function formatRating(rating) {
    var value = rating || 0;
    if (!isFinite(value) || value <= 0) {
      return "";
    }

    var stars = "";
    for (var i = 0; i < value; i++) {
      stars += "\u2605";
    }
    return stars;
  }

  function formatPlayCount(count) {
    var plays = count || 0;
    if (!isFinite(plays) || plays <= 0) {
      return "";
    }
    return plays === 1 ? pluginApi?.tr("common.onePlay") : pluginApi?.tr("common.plays", {"count": plays});
  }

  function formatSpeed(speed) {
    var value = speed || 1;
    if (!isFinite(value)) {
      return pluginApi?.tr("speed.multiplier", {"speed": "1.00"});
    }

    var rounded = Math.round(value * 100) / 100;
    return pluginApi?.tr("speed.multiplier", {"speed": rounded.toFixed(2)});
  }

  function effectiveSeekPosition() {
    var duration = mainInstance?.currentDuration || 0;
    if (seekDragging && localSeekRatio >= 0 && duration > 0) {
      return Math.max(0, Math.min(duration, localSeekRatio * duration));
    }
    return Math.max(0, mainInstance?.currentPosition || 0);
  }

  function entrySummary(entry, section) {
    var normalized = normalizedEntry(entry);
    var parts = [];

    if (normalized.uploader.length > 0) {
      parts.push(normalized.uploader);
    }

    var duration = MusicUtils.formatDuration(normalized.duration);
    if (duration.length > 0) {
      parts.push(duration);
    }

    if (section === "search") {
      parts.push(providerLabel(normalized.provider || parseSearchProviderQuery(trimmedSearchText()).provider));
    } else if (section === "library") {
      var rating = formatRating(normalized.rating);
      if (rating.length > 0) {
        parts.push(rating);
      }
      var playCount = formatPlayCount(normalized.playCount);
      if (playCount.length > 0) {
        parts.push(playCount);
      }
      if (normalized.tags.length > 0) {
        parts.push(normalized.tags.map(function (tag) { return "#" + tag; }).join(" "));
      }
    } else if (section === "queue") {
      var queuedAt = MusicUtils.formatRelativeTime(normalized.queuedAt);
      if (queuedAt.length > 0) {
        parts.push(pluginApi?.tr("panel.queuedAt", {"time": queuedAt}));
      }
    }

    return parts.join(" • ");
  }

  function isCurrentEntry(entry) {
    var normalized = normalizedEntry(entry);
    if (!hasPlayback) {
      return false;
    }
    if (normalized.id.length > 0 && normalized.id === (mainInstance?.currentEntryId || "")) {
      return true;
    }
    return normalized.url.length > 0 && normalized.url === (mainInstance?.currentUrl || "");
  }

  function isRemoteEntry(entry) {
    var normalized = normalizedEntry(entry);
    return normalized.url.length > 0 && !normalized.url.startsWith("/");
  }

  function closePanel() {
    var screen = pluginApi?.panelOpenScreen;
    if (screen) {
      pluginApi.closePanel(screen);
      return;
    }

    pluginApi?.withCurrentScreen(function (currentScreen) {
      pluginApi.closePanel(currentScreen);
    });
  }

  function openSettings() {
    var screen = pluginApi?.panelOpenScreen;
    if (screen) {
      BarService.openPluginSettings(screen, pluginApi.manifest);
      return;
    }

    pluginApi?.withCurrentScreen(function (currentScreen) {
      BarService.openPluginSettings(currentScreen, pluginApi.manifest);
    });
  }

  function previewItemsEqual(left, right) {
    var leftId = String(left?.id || "").trim();
    var rightId = String(right?.id || "").trim();
    if (leftId.length > 0 && rightId.length > 0) {
      return leftId === rightId;
    }

    var leftUrl = String(left?.url || "").trim();
    var rightUrl = String(right?.url || "").trim();
    return leftUrl.length > 0 && leftUrl === rightUrl;
  }

  function buildPanelPreviewItem(entry, section) {
    var normalized = normalizedEntry(entry);
    if ((normalized.id || "").length === 0 && (normalized.url || "").length === 0) {
      return null;
    }

    var providerKey = normalized.provider || mainInstance?.currentProvider || "youtube";
    return {
      "id": normalized.id,
      "name": normalized.title,
      "title": normalized.title,
      "url": normalized.url,
      "uploader": normalized.uploader,
      "duration": normalized.duration,
      "album": normalized.album,
      "tags": normalized.tags.slice(),
      "helperPath": helperPath,
      "previewDelayMs": 350,
      "provider": root,
      "sourceLabel": providerLabel(providerKey),
      "isSaved": mainInstance?.isSaved(normalized) === true,
      "isPlaying": isCurrentEntry(normalized),
      "isStarting": isCurrentEntry(normalized) && mainInstance?.playbackStarting === true
    };
  }

  function playbackPreviewEntry() {
    if (!hasPlayback) {
      return null;
    }

    return buildPanelPreviewItem({
                                   "id": mainInstance?.currentEntryId || "",
                                   "title": mainInstance?.currentTitle || "",
                                   "url": mainInstance?.currentUrl || "",
                                   "uploader": mainInstance?.currentUploader || "",
                                   "duration": mainInstance?.currentDuration || 0,
                                   "provider": mainInstance?.currentProvider || ""
                                 }, "queue");
  }

  function setPanelPreviewEntry(entry, section) {
    var nextItem = buildPanelPreviewItem(entry, section);
    if (!nextItem) {
      return;
    }

    if (!panelPreviewFollowsPlayback && previewItemsEqual(panelPreviewItem, nextItem)) {
      clearPanelPreview();
      return;
    }

    panelPreviewItem = nextItem;
    panelPreviewFollowsPlayback = false;
    panelPreviewDismissed = false;
  }

  function clearPanelPreview() {
    panelPreviewItem = null;
    panelPreviewFollowsPlayback = false;
    panelPreviewDismissed = true;
  }

  function syncPanelPlaybackPreview(force) {
    if (!showPanelPreview) {
      return;
    }

    if (force === true) {
      panelPreviewDismissed = false;
    } else if (panelPreviewDismissed) {
      return;
    }

    if (!hasPlayback) {
      if (force === true || panelPreviewFollowsPlayback) {
        panelPreviewItem = null;
      }
      return;
    }

    if (force === true || panelPreviewFollowsPlayback || !panelPreviewItem) {
      panelPreviewItem = playbackPreviewEntry();
      panelPreviewFollowsPlayback = true;
    }
  }

  function clampPreviewPaneWidth(value) {
    var availableWidth = panelTabsRow?.width || 0;
    var maxWidth = availableWidth > 0
        ? Math.min(previewPaneMaxWidthCap, Math.max(previewPaneMinWidth, availableWidth * 0.48))
        : previewPaneMaxWidthCap;
    return Math.max(previewPaneMinWidth, Math.min(maxWidth, value || 0));
  }

  function persistPreviewPaneWidth(value, flush) {
    var rawWidth = Number(value || 0);
    if (!isFinite(rawWidth) || rawWidth <= 0) {
      return previewPaneWidth;
    }
    preferredPreviewPaneWidth = rawWidth;
    var nextWidth = clampPreviewPaneWidth(rawWidth);
    previewPaneWidth = nextWidth;
    if (pluginApi?.pluginSettings) {
      pluginApi.pluginSettings.previewPaneWidth = rawWidth;
    }
    if (flush === true && pluginApi) {
      pluginApi.saveSettings();
    }
    return nextWidth;
  }

  function savedPreviewPaneWidth() {
    var value = Number(pluginApi?.pluginSettings?.previewPaneWidth
                       ?? defaults.previewPaneWidth
                       ?? 0);
    if (!isFinite(value) || value <= 0) {
      return 0;
    }
    return value;
  }

  function ensurePreviewPaneWidth(force) {
    if (!showPanelPreview || !panelPreviewItem) {
      return;
    }

    if (force === true || preferredPreviewPaneWidth <= 0) {
      preferredPreviewPaneWidth = savedPreviewPaneWidth();
    }

    if (force === true || previewPaneWidth <= 0) {
      if (preferredPreviewPaneWidth > 0) {
        previewPaneWidth = clampPreviewPaneWidth(preferredPreviewPaneWidth);
        return;
      }
      var availableWidth = panelTabsRow?.width || 0;
      var fallbackWidth = availableWidth > 0
          ? Math.round(availableWidth * 0.34)
          : Math.round(320 * Style.uiScaleRatio);
      preferredPreviewPaneWidth = fallbackWidth;
      previewPaneWidth = clampPreviewPaneWidth(preferredPreviewPaneWidth);
      return;
    }

    if (preferredPreviewPaneWidth > 0) {
      previewPaneWidth = clampPreviewPaneWidth(preferredPreviewPaneWidth);
    } else {
      previewPaneWidth = clampPreviewPaneWidth(previewPaneWidth);
    }
  }

  component ProviderChip: Rectangle {
    id: chip

    property string providerKey: "youtube"
    readonly property bool active: (root.mainInstance?.currentProvider || "youtube") === providerKey

    radius: Style.radiusM
    color: active ? (Color.mPrimaryContainer || Qt.alpha(Color.mPrimary, 0.14) || Color.mSurfaceVariant) : Color.mSurfaceVariant
    border.width: 1
    border.color: active ? Color.mPrimary : Qt.alpha((Color.mOutline || Color.mOnSurfaceVariant || "#888888"), 0.35)
    implicitWidth: providerLabelText.implicitWidth + (Style.marginL * 2)
    implicitHeight: providerLabelText.implicitHeight + (Style.marginS * 2)

    NText {
      id: providerLabelText
      anchors.centerIn: parent
      text: root.providerLabel(chip.providerKey)
      color: chip.active ? (Color.mOnPrimaryContainer || Color.mOnSurface) : Color.mOnSurface
      pointSize: Style.fontSizeS
      font.weight: chip.active ? Font.DemiBold : Font.Normal
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.mainInstance?.setProvider(chip.providerKey)
    }
  }

  component TrackCard: Rectangle {
    id: card

    property var entry: null
    property string section: "search"

    readonly property var normalized: root.normalizedEntry(entry)
    readonly property bool saved: root.mainInstance?.isSaved(normalized) === true
    readonly property bool current: root.isCurrentEntry(normalized)
    readonly property bool remoteEntry: root.isRemoteEntry(normalized)
    readonly property bool previewSelected: root.previewItemsEqual(root.panelPreviewItem, normalized)

    Layout.fillWidth: true
    radius: root.panelCardRadius
    color: current ? (Color.mSurface || Color.mSurfaceVariant) : Color.mSurfaceVariant
    border.width: (current || previewSelected) ? Style.borderS : 0
    border.color: current
        ? (Color.mPrimary || Color.mOnSurface)
        : (previewSelected ? Qt.alpha((Color.mPrimary || Color.mOnSurface), 0.5) : "transparent")
    implicitHeight: content.implicitHeight + (root.panelCardPadding * 2)

    ColumnLayout {
      id: content
      anchors.fill: parent
      anchors.margins: root.panelCardPadding
      spacing: root.panelCardSpacing

      Item {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight

        RowLayout {
          id: headerRow
          anchors.fill: parent
          spacing: root.panelCardHeaderSpacing

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.max(Style.marginXXS, Math.round(root.panelCardSpacing * 0.5))

            NText {
              Layout.fillWidth: true
              text: normalized.title
              color: Color.mOnSurface
              pointSize: root.panelTitleSize
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }

            NText {
              Layout.fillWidth: true
              text: root.entrySummary(normalized, section)
              visible: text.length > 0
              color: Color.mOnSurfaceVariant
              pointSize: root.panelBodySize
              wrapMode: Text.Wrap
            }
          }

          Rectangle {
            visible: saved
            radius: Style.radiusM
            color: current ? Qt.alpha(Color.mPrimary, 0.16) : Qt.alpha(Color.mPrimary, 0.12)
            implicitWidth: savedLabel.implicitWidth + (Style.marginM * 2)
            implicitHeight: savedLabel.implicitHeight + (Style.marginXS * 2)

            NText {
              id: savedLabel
              anchors.centerIn: parent
              text: root.pluginApi?.tr("panel.savedLabel")
              color: Color.mPrimary
              pointSize: root.panelBadgeSize
              font.weight: Font.DemiBold
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor
          onClicked: root.setPanelPreviewEntry(normalized, section)
        }
      }

      Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: root.panelCardSpacing

        NButton {
          text: current
              ? (root.mainInstance?.isPaused === true
                  ? root.pluginApi?.tr("panel.resume")
                  : root.pluginApi?.tr("panel.pause"))
              : root.pluginApi?.tr("panel.playAction")
          icon: current
              ? (root.mainInstance?.isPaused === true ? "player-play-filled" : "player-pause-filled")
              : "player-play-filled"
          fontSize: root.panelButtonSize
          onClicked: {
            if (current) {
              root.mainInstance?.togglePause();
            } else if (section === "queue") {
              root.mainInstance?.playQueueEntryNow(normalized);
            } else {
              root.mainInstance?.playEntry(normalized);
            }
          }
        }

        NButton {
          text: root.pluginApi?.tr("panel.queueAction")
          icon: "list"
          fontSize: root.panelButtonSize
          visible: section !== "queue"
          onClicked: root.mainInstance?.enqueueEntry(normalized)
        }

        NButton {
          text: root.pluginApi?.tr("panel.saveAction")
          icon: "bookmark-plus"
          fontSize: root.panelButtonSize
          visible: !saved && section !== "queue"
          onClicked: root.mainInstance?.saveEntry(normalized)
        }

        NButton {
          text: root.pluginApi?.tr("panel.downloadAction")
          icon: "download"
          fontSize: root.panelButtonSize
          visible: section !== "queue" && remoteEntry
          onClicked: root.mainInstance?.downloadEntry(normalized)
        }

        NButton {
          text: root.pluginApi?.tr("panel.removeAction")
          icon: "trash"
          fontSize: root.panelButtonSize
          visible: section === "queue" || section === "library"
          onClicked: {
            if (section === "queue") {
              root.mainInstance?.removeQueueEntry(normalized.id, true);
            } else {
              root.mainInstance?.removeEntry(normalized.id);
            }
          }
        }
      }
    }
  }

  component LibraryBrowseCard: Rectangle {
    id: browseCard

    property string title: ""
    property string description: ""
    property string accentText: ""
    property string iconText: ""
    property var primaryAction: null
    property var secondaryAction: null
    property var tertiaryAction: null
    property var quaternaryAction: null

    Layout.fillWidth: true
    radius: root.panelCardRadius
    color: Color.mSurfaceVariant
    implicitHeight: browseContent.implicitHeight + (root.panelCardPadding * 2)

    ColumnLayout {
      id: browseContent
      anchors.fill: parent
      anchors.margins: root.panelCardPadding
      spacing: root.panelCardSpacing

      RowLayout {
        Layout.fillWidth: true
        spacing: root.panelCardHeaderSpacing

        Rectangle {
          visible: browseCard.iconText.length > 0
          radius: Style.radiusM
          color: Qt.alpha(Color.mPrimary, 0.14)
          implicitWidth: Math.max(iconLabel.implicitWidth, Math.round(24 * Style.uiScaleRatio)) + Style.marginS
          implicitHeight: Math.max(iconLabel.implicitHeight, Math.round(24 * Style.uiScaleRatio)) + Style.marginXS

          NText {
            id: iconLabel
            anchors.centerIn: parent
            text: browseCard.iconText
            color: Color.mPrimary
            pointSize: Style.fontSizeS
            font.weight: Font.DemiBold
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Math.max(Style.marginXXS, Math.round(root.panelCardSpacing * 0.5))

          NText {
            Layout.fillWidth: true
            text: browseCard.title
            color: Color.mOnSurface
            pointSize: root.panelTitleSize
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
          }

          NText {
            Layout.fillWidth: true
            visible: browseCard.description.length > 0
            text: browseCard.description
            color: Color.mOnSurfaceVariant
            pointSize: root.panelBodySize
            wrapMode: Text.Wrap
          }
        }

        Rectangle {
          visible: browseCard.accentText.length > 0
          radius: Style.radiusM
          color: Qt.alpha(Color.mPrimary, 0.18)
          implicitWidth: accentLabel.implicitWidth + (Style.marginM * 2)
          implicitHeight: accentLabel.implicitHeight + (Style.marginXS * 2)

          NText {
            id: accentLabel
            anchors.centerIn: parent
            text: browseCard.accentText
            color: Color.mPrimary
            pointSize: root.panelBodySize
            font.weight: Font.DemiBold
          }
        }
      }

      Flow {
        Layout.fillWidth: true
        spacing: root.panelCardSpacing

        Repeater {
          model: [browseCard.primaryAction, browseCard.secondaryAction, browseCard.tertiaryAction, browseCard.quaternaryAction]

          delegate: NButton {
            required property var modelData

            visible: !!modelData
            text: modelData?.text || ""
            icon: modelData?.icon || ""
            fontSize: root.panelButtonSize
            onClicked: {
              if (modelData?.onClicked) {
                modelData.onClicked();
              }
            }
          }
        }
      }
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: root.panelSectionSpacing

      Rectangle {
        visible: root.showPanelHeader
        Layout.fillWidth: true
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        implicitHeight: headerContent.implicitHeight + (Style.marginL * 2)

        RowLayout {
          id: headerContent
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginM

          NIcon {
            icon: "music"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            NText {
              text: pluginApi?.tr("panel.title")
              color: Color.mOnSurface
              pointSize: Style.fontSizeL
              font.weight: Font.Bold
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("panel.subtitle")
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              wrapMode: Text.Wrap
            }
          }

          NButton {
            text: pluginApi?.tr("panel.openLauncher")
            icon: "search"
            fontSize: Style.fontSizeS
            onClicked: {
              root.closePanel();
              mainInstance?.openLauncher();
            }
          }

          NIconButton {
            icon: "settings"
            tooltipText: pluginApi?.tr("panel.openSettings")
            onClicked: root.openSettings()
          }

          NIconButton {
            icon: "x"
            tooltipText: pluginApi?.tr("panel.close")
            onClicked: root.closePanel()
          }
        }
      }

      Rectangle {
        visible: root.showPanelNowPlaying
        Layout.fillWidth: true
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        implicitHeight: playbackColumn.implicitHeight + (Style.marginL * 2)

        ColumnLayout {
          id: playbackColumn
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: root.panelCardSpacing

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: pluginApi?.tr("panel.nowPlaying")
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                font.weight: Font.DemiBold
              }

              NText {
                Layout.fillWidth: true
                text: {
                  if (mainInstance?.playbackStarting === true && (mainInstance?.currentTitle || "").trim().length === 0) {
                    return pluginApi?.tr("status.starting");
                  }
                  return (mainInstance?.currentTitle || "").trim() || pluginApi?.tr("panel.nothingPlaying");
                }
                color: Color.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
              }

              NText {
                Layout.fillWidth: true
                visible: root.hasPlayback
                text: {
                  var parts = [];
                  var uploader = (mainInstance?.currentUploader || "").trim();
                  var provider = root.providerLabel(mainInstance?.currentProvider || "youtube");
                  var duration = MusicUtils.formatDuration(mainInstance?.currentDuration || 0);
                  if (uploader.length > 0) {
                    parts.push(uploader);
                  }
                  if (provider.length > 0) {
                    parts.push(provider);
                  }
                  if (duration.length > 0) {
                    parts.push(duration);
                  }
                  return parts.join(" • ");
                }
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                wrapMode: Text.Wrap
              }
            }

            NButton {
              text: mainInstance?.isPaused === true ? pluginApi?.tr("panel.resume") : pluginApi?.tr("panel.pause")
              icon: mainInstance?.isPaused === true ? "player-play-filled" : "player-pause-filled"
              fontSize: Style.fontSizeS
              enabled: mainInstance?.isPlaying === true
              onClicked: mainInstance?.togglePause()
            }

            NButton {
              text: pluginApi?.tr("panel.stop")
              icon: "player-stop-filled"
              fontSize: Style.fontSizeS
              enabled: root.hasPlayback
              onClicked: mainInstance?.stopPlayback()
            }
          }

          NSlider {
            id: playbackSlider
            visible: root.showPanelPlaybackProgress
            Layout.fillWidth: true
            from: 0
            to: 1
            stepSize: 0
            snapAlways: false
            heightRatio: 0.4
            enabled: mainInstance?.isPlaying === true && (mainInstance?.currentDuration || 0) > 0
            value: {
              var duration = mainInstance?.currentDuration || 0;
              if (!isFinite(duration) || duration <= 0) {
                return 0;
              }
              if (root.seekDragging && root.localSeekRatio >= 0) {
                return Math.max(0, Math.min(1, root.localSeekRatio));
              }
              return Math.max(0, Math.min(1, (mainInstance?.currentPosition || 0) / duration));
            }

            onMoved: {
              root.seekDragging = true;
              root.localSeekRatio = value;
            }
            onPressedChanged: {
              if (pressed) {
                root.seekDragging = true;
                root.localSeekRatio = value;
              } else {
                if (enabled) {
                  root.mainInstance?.seekToRatio(value);
                }
                root.seekDragging = false;
                root.localSeekRatio = -1;
              }
            }
          }

          RowLayout {
            visible: root.showPanelPlaybackProgress
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
              text: MusicUtils.formatDuration(root.effectiveSeekPosition())
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
            }

            Item {
              Layout.fillWidth: true
            }

            NText {
              text: MusicUtils.formatDuration(mainInstance?.currentDuration || 0)
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
              text: pluginApi?.tr("panel.saveCurrent")
              icon: "bookmark-plus"
              fontSize: Style.fontSizeS
              enabled: root.hasPlayback && mainInstance?.findSavedEntry({
                                                     "id": mainInstance?.currentEntryId || "",
                                                     "url": mainInstance?.currentUrl || ""
                                                   }) === null
              onClicked: mainInstance?.saveEntry({
                                                   "id": mainInstance?.currentEntryId || "",
                                                   "title": mainInstance?.currentTitle || "",
                                                   "url": mainInstance?.currentUrl || "",
                                                   "uploader": mainInstance?.currentUploader || "",
                                                   "duration": mainInstance?.currentDuration || 0,
                                                   "provider": mainInstance?.currentProvider || ""
                                                 })
            }

            NButton {
              text: pluginApi?.tr("panel.saveCurrentMp3")
              icon: "download"
              fontSize: Style.fontSizeS
              enabled: root.hasPlayback && root.isRemoteEntry({
                                               "url": mainInstance?.currentUrl || "",
                                               "provider": mainInstance?.currentProvider || ""
                                             })
              onClicked: mainInstance?.downloadCurrentTrack()
            }

            NButton {
              text: pluginApi?.tr("panel.refresh")
              icon: "refresh"
              fontSize: Style.fontSizeS
              onClicked: mainInstance?.refreshStatus(true)
            }

            Item {
              Layout.fillWidth: true
              implicitHeight: playbackStatusText.visible ? playbackStatusText.implicitHeight : 0

              NText {
                id: playbackStatusText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: (mainInstance?.playbackStartingMessage || "").trim()
                visible: mainInstance?.playbackStarting === true && text.length > 0
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
              }
            }

            RowLayout {
              visible: root.hasPlayback && root.showPanelSpeedControls
              spacing: Math.max(2, Math.round(Style.marginXS * 0.5))

              NButton {
                text: "-"
                backgroundColor: "transparent"
                textColor: Color.mOnSurfaceVariant
                outlined: false
                enabled: mainInstance?.isPlaying === true && mainInstance?.speedBusy !== true
                implicitWidth: Math.round(24 * Style.uiScaleRatio)
                implicitHeight: Math.round(24 * Style.uiScaleRatio)
                onClicked: mainInstance?.adjustSpeed(-0.05)
              }

              Rectangle {
                radius: Style.radiusM
                color: Color.mPrimary
                implicitHeight: Math.round(24 * Style.uiScaleRatio)
                implicitWidth: Math.max(speedChipLabel.implicitWidth, speedChipWidthReference.implicitWidth) + Math.round(18 * Style.uiScaleRatio)
                opacity: mainInstance?.speedBusy === true ? 0.75 : 1

                NText {
                  id: speedChipLabel
                  anchors.centerIn: parent
                  text: root.formatSpeed(mainInstance?.currentSpeed || 1)
                  pointSize: Style.fontSizeS
                  color: Color.mOnPrimary
                }

                NText {
                  id: speedChipWidthReference
                  visible: false
                  text: root.formatSpeed(4)
                  pointSize: Style.fontSizeS
                }

                MouseArea {
                  anchors.fill: parent
                  acceptedButtons: Qt.LeftButton
                  enabled: mainInstance?.isPlaying === true && mainInstance?.speedBusy !== true
                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                  onClicked: mainInstance?.setSpeed(1)
                  onWheel: wheel => {
                             if (!enabled || wheel.angleDelta.y === 0) {
                               return;
                             }

                             mainInstance?.adjustSpeed(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
                             wheel.accepted = true;
                           }
                }
              }

              NButton {
                text: "+"
                backgroundColor: "transparent"
                textColor: Color.mOnSurfaceVariant
                outlined: false
                enabled: mainInstance?.isPlaying === true && mainInstance?.speedBusy !== true
                implicitWidth: Math.round(24 * Style.uiScaleRatio)
                implicitHeight: Math.round(24 * Style.uiScaleRatio)
                onClicked: mainInstance?.adjustSpeed(0.05)
              }
            }
          }
        }
      }

      Rectangle {
        visible: root.showPanelStatusBanner
            && ((mainInstance?.lastError || "").trim().length > 0 || (mainInstance?.lastNotice || "").trim().length > 0)
        Layout.fillWidth: true
        radius: Style.radiusM
        color: (mainInstance?.lastError || "").trim().length > 0 ? Qt.alpha(Color.mError, 0.14) : Qt.alpha(Color.mPrimary, 0.12)
        implicitHeight: statusText.implicitHeight + (Style.marginM * 2)

        NText {
          id: statusText
          anchors.fill: parent
          anchors.margins: Style.marginM
          text: (mainInstance?.lastError || "").trim().length > 0 ? (mainInstance?.lastError || "").trim() : (mainInstance?.lastNotice || "").trim()
          color: (mainInstance?.lastError || "").trim().length > 0 ? Color.mError : Color.mOnSurface
          pointSize: Style.fontSizeS
          wrapMode: Text.Wrap
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        clip: true

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NTabBar {
            id: tabBar
            Layout.fillWidth: true
            distributeEvenly: true
            currentIndex: root.activeTab === "library" ? 1 : (root.activeTab === "queue" ? 2 : 0)

            NTabButton {
              text: pluginApi?.tr("panel.search")
              tabIndex: 0
              checked: tabBar.currentIndex === 0
              onClicked: root.activeTab = "search"
            }

            NTabButton {
              text: pluginApi?.tr("panel.library")
              tabIndex: 1
              checked: tabBar.currentIndex === 1
              onClicked: root.activeTab = "library"
            }

            NTabButton {
              text: pluginApi?.tr("panel.queue")
              tabIndex: 2
              checked: tabBar.currentIndex === 2
              onClicked: root.activeTab = "queue"
            }
          }

          RowLayout {
            id: panelTabsRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.marginM

            onWidthChanged: root.ensurePreviewPaneWidth(false)

            Item {
              id: tabViewContainer
              Layout.fillWidth: true
              Layout.fillHeight: true

              NTabView {
                id: tabView
                anchors.fill: parent
                currentIndex: tabBar.currentIndex

              Item {
                height: tabView.height

                ColumnLayout {
                  anchors.fill: parent
                  spacing: Style.marginM

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  NTextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: pluginApi?.tr("panel.searchPlaceholder")
                    text: root.searchText

                    onTextChanged: {
                      root.searchText = text;
                      searchDelay.restart();
                    }

                    Keys.onReturnPressed: root.performSearch(true)
                    Keys.onEnterPressed: root.performSearch(true)
                  }

                  NButton {
                    text: pluginApi?.tr("panel.search")
                    icon: "search"
                    fontSize: Style.fontSizeS
                    enabled: !root.searchBusy
                    onClicked: root.performSearch(true)
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginS
                  visible: root.showPanelProviderChips

                  ProviderChip { providerKey: "youtube" }
                  ProviderChip { providerKey: "soundcloud" }
                  ProviderChip { providerKey: "local" }

                  Item { Layout.fillWidth: true }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: root.panelCardSpacing
                  visible: root.showPanelUrlActions && root.looksLikeUrl(root.trimmedSearchText())

                  NButton {
                    text: pluginApi?.tr("panel.playUrl")
                    icon: "player-play-filled"
                    fontSize: Style.fontSizeS
                    onClicked: root.mainInstance?.playUrl(root.trimmedSearchText(), pluginApi?.tr("common.customUrl"))
                  }

                  NButton {
                    text: pluginApi?.tr("panel.saveUrl")
                    icon: "bookmark-plus"
                    fontSize: Style.fontSizeS
                    onClicked: root.mainInstance?.saveUrl(root.trimmedSearchText())
                  }

                  NButton {
                    text: pluginApi?.tr("panel.queueUrl")
                    icon: "list"
                    fontSize: Style.fontSizeS
                    onClicked: root.mainInstance?.enqueueUrl(root.trimmedSearchText(), pluginApi?.tr("common.queuedUrl"))
                  }
                }

                NScrollView {
                  id: searchScroll
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  Layout.bottomMargin: Style.marginS
                  horizontalPolicy: ScrollBar.AlwaysOff
                  verticalPolicy: ScrollBar.AsNeeded
                  reserveScrollbarSpace: false
                  gradientColor: Color.mSurfaceVariant
                  bottomPadding: Style.marginS

                  ColumnLayout {
                    width: searchScroll.availableWidth
                    spacing: Style.marginM

                    Rectangle {
                      visible: root.searchBusy
                      Layout.fillWidth: true
                      radius: Style.radiusL
                      color: Qt.alpha(Color.mPrimary, 0.08)
                      implicitHeight: loadingRow.implicitHeight + (Style.marginL * 2)

                      RowLayout {
                        id: loadingRow
                        anchors.centerIn: parent
                        spacing: Style.marginM

                        NBusyIndicator {
                          running: root.searchBusy
                          color: Color.mPrimary
                          size: Style.baseWidgetSize * 0.75
                        }

                        NText {
                          text: pluginApi?.tr("panel.searching", {"provider": root.providerLabel(root.runningSearchProvider || root.parseSearchProviderQuery(root.trimmedSearchText()).provider)})
                          color: Color.mOnSurface
                          pointSize: Style.fontSizeS
                        }
                      }
                    }

                    Rectangle {
                      visible: !root.searchBusy && (root.searchError || "").trim().length > 0
                      Layout.fillWidth: true
                      radius: Style.radiusL
                      color: Qt.alpha(Color.mError, 0.12)
                      implicitHeight: searchErrorText.implicitHeight + (Style.marginL * 2)

                      NText {
                        id: searchErrorText
                        anchors.fill: parent
                        anchors.margins: Style.marginL
                        text: root.searchError
                        color: Color.mError
                        pointSize: Style.fontSizeS
                        wrapMode: Text.Wrap
                      }
                    }

                    Rectangle {
                      visible: !root.searchBusy && !root.looksLikeUrl(root.trimmedSearchText()) && root.trimmedSearchText().length > 0 && root.parseSearchProviderQuery(root.trimmedSearchText()).query.length > 0 && root.parseSearchProviderQuery(root.trimmedSearchText()).query.length < 2
                      Layout.fillWidth: true
                      radius: Style.radiusL
                      color: Qt.alpha(Color.mSurface, 0.6)
                      implicitHeight: shortSearchText.implicitHeight + (Style.marginL * 2)

                      NText {
                        id: shortSearchText
                        anchors.fill: parent
                        anchors.margins: Style.marginL
                        text: pluginApi?.tr("panel.typeMore", {"provider": root.providerLabel(root.parseSearchProviderQuery(root.trimmedSearchText()).provider)})
                        color: Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeS
                        wrapMode: Text.Wrap
                      }
                    }

                    Rectangle {
                      visible: root.showPanelSearchHelper
                          && !root.searchBusy
                          && root.trimmedSearchText().length === 0
                      Layout.fillWidth: true
                      radius: Style.radiusL
                      color: Qt.alpha(Color.mSurface, 0.6)
                      implicitHeight: helperColumn.implicitHeight + (Style.marginL * 2)

                      ColumnLayout {
                        id: helperColumn
                        anchors.fill: parent
                        anchors.margins: Style.marginL
                        spacing: Style.marginS

                        NText {
                          Layout.fillWidth: true
                          text: pluginApi?.tr("panel.searchHint", {"provider": root.providerLabel(mainInstance?.currentProvider || "youtube")})
                          color: Color.mOnSurface
                          pointSize: Style.fontSizeS
                          wrapMode: Text.Wrap
                        }

                        NText {
                          Layout.fillWidth: true
                          text: pluginApi?.tr("panel.helperHint")
                          color: Color.mOnSurfaceVariant
                          pointSize: Style.fontSizeXS
                          wrapMode: Text.Wrap
                        }
                      }
                    }

                    NText {
                      Layout.fillWidth: true
                      visible: root.showPanelRecentTracks
                          && !root.searchBusy
                          && root.trimmedSearchText().length === 0
                          && root.recentLibraryEntries.length > 0
                      text: pluginApi?.tr("panel.recentTracks")
                      color: Color.mOnSurface
                      pointSize: Style.fontSizeM
                      font.weight: Font.DemiBold
                    }

                    Repeater {
                      model: root.showPanelRecentTracks
                          && !root.searchBusy
                          && root.trimmedSearchText().length === 0
                          ? root.recentLibraryEntries
                          : []

                      delegate: TrackCard {
                        entry: modelData
                        section: "library"
                      }
                    }

                    NText {
                      Layout.fillWidth: true
                      visible: !root.searchBusy && root.trimmedSearchText().length > 0 && !root.looksLikeUrl(root.trimmedSearchText()) && root.parseSearchProviderQuery(root.trimmedSearchText()).query.length >= 2 && root.searchResults.length === 0 && (root.searchError || "").trim().length === 0
                      text: pluginApi?.tr("panel.noSearchResults", {"query": root.parseSearchProviderQuery(root.trimmedSearchText()).query})
                      color: Color.mOnSurfaceVariant
                      pointSize: Style.fontSizeS
                      wrapMode: Text.Wrap
                    }

                    Repeater {
                      model: !root.searchBusy && root.trimmedSearchText().length > 0 && !root.looksLikeUrl(root.trimmedSearchText()) ? root.searchResults : []

                      delegate: TrackCard {
                        entry: modelData
                        section: "search"
                      }
                    }
                  }
                }
              }
            }

            Item {
              height: tabView.height

              ColumnLayout {
                anchors.fill: parent
                spacing: root.panelSectionSpacing

                NTabBar {
                  id: libraryTabBar
                  Layout.fillWidth: true
                  distributeEvenly: true
                  currentIndex: root.librarySection === "playlists"
                      ? 1
                      : (root.librarySection === "artists"
                          ? 2
                          : (root.librarySection === "tags" ? 3 : 0))

                  NTabButton {
                    text: pluginApi?.tr("panel.tracks")
                    tabIndex: 0
                    checked: libraryTabBar.currentIndex === 0
                    onClicked: root.setLibrarySection("tracks")
                  }

                  NTabButton {
                    text: pluginApi?.tr("panel.playlists")
                    tabIndex: 1
                    checked: libraryTabBar.currentIndex === 1
                    onClicked: root.setLibrarySection("playlists")
                  }

                  NTabButton {
                    text: pluginApi?.tr("panel.artists")
                    tabIndex: 2
                    checked: libraryTabBar.currentIndex === 2
                    onClicked: root.setLibrarySection("artists")
                  }

                  NTabButton {
                    text: pluginApi?.tr("panel.tags")
                    tabIndex: 3
                    checked: libraryTabBar.currentIndex === 3
                    onClicked: root.setLibrarySection("tags")
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: root.panelCardSpacing

                  NTextInput {
                    id: libraryFilterInput
                    Layout.fillWidth: true
                    placeholderText: root.libraryPlaceholderText()
                    text: root.libraryFilterText
                    onTextChanged: root.libraryFilterText = text
                  }

                  NButton {
                    text: pluginApi?.tr("panel.playSaved")
                    icon: "player-play-filled"
                    fontSize: Style.fontSizeS
                    visible: !root.hasLibrarySelection() && root.librarySection === "tracks"
                    enabled: (mainInstance?.visibleLibraryEntries() || []).length > 0
                    onClicked: root.mainInstance?.autoplaySavedTracks(false)
                  }

                  NButton {
                    text: pluginApi?.tr("panel.shuffleSaved")
                    icon: "arrows-shuffle"
                    fontSize: Style.fontSizeS
                    visible: !root.hasLibrarySelection() && root.librarySection === "tracks"
                    enabled: (mainInstance?.visibleLibraryEntries() || []).length > 0
                    onClicked: root.mainInstance?.autoplaySavedTracks(true)
                  }

                  NButton {
                    text: pluginApi?.tr("panel.backAction")
                    icon: "arrow-left"
                    fontSize: Style.fontSizeS
                    visible: root.hasLibrarySelection()
                    onClicked: root.clearLibrarySelection()
                  }

                  NButton {
                    text: pluginApi?.tr("panel.playAction")
                    icon: "player-play-filled"
                    fontSize: Style.fontSizeS
                    visible: root.hasLibrarySelection()
                    enabled: root.activeLibrarySelectionList.length > 0
                    onClicked: root.playCurrentLibrarySelection(false)
                  }

                  NButton {
                    text: pluginApi?.tr("panel.shuffleAction")
                    icon: "arrows-shuffle"
                    fontSize: Style.fontSizeS
                    visible: root.hasLibrarySelection()
                    enabled: root.activeLibrarySelectionList.length > 0
                    onClicked: root.playCurrentLibrarySelection(true)
                  }

                  NButton {
                    text: pluginApi?.tr("panel.queueAction")
                    icon: "list"
                    fontSize: Style.fontSizeS
                    visible: root.hasLibrarySelection()
                    enabled: root.activeLibrarySelectionList.length > 0
                    onClicked: root.queueCurrentLibrarySelection(false)
                  }
                }

                NText {
                  Layout.fillWidth: true
                  text: {
                    if (root.hasLibrarySelection()) {
                      return root.activeLibrarySelectionTitle().length > 0
                          ? (root.activeLibrarySelectionTitle() + " • " + pluginApi?.tr("playlists.trackCount", {"count": root.activeLibrarySelectionList.length}))
                          : pluginApi?.tr("playlists.trackCount", {"count": root.activeLibrarySelectionList.length});
                    }
                    if (root.librarySection === "playlists") {
                      return pluginApi?.tr("panel.playlistCount", {"count": root.filteredPlaylistEntries.length});
                    }
                    if (root.librarySection === "artists") {
                      return pluginApi?.tr("panel.artistCount", {"count": root.filteredArtistStats.length});
                    }
                    if (root.librarySection === "tags") {
                      return pluginApi?.tr("panel.tagCount", {"count": root.filteredTagStats.length});
                    }
                    return pluginApi?.tr("panel.savedCount", {"count": root.filteredLibraryEntries.length});
                  }
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeS
                }

                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  Layout.bottomMargin: Style.marginS

                  NText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    visible: (root.hasLibrarySelection() || root.librarySection === "tracks")
                        && root.activeLibraryTrackList.length === 0
                    text: root.hasLibrarySelection()
                        ? pluginApi?.tr("panel.emptyScopedLibrary")
                        : pluginApi?.tr("panel.emptyLibrary")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    wrapMode: Text.Wrap
                  }

                  NListView {
                    id: libraryTrackList
                    anchors.fill: parent
                    visible: (root.hasLibrarySelection() || root.librarySection === "tracks")
                        && root.activeLibraryTrackList.length > 0
                    spacing: Style.marginM
                    cacheBuffer: Math.round(1000 * Style.uiScaleRatio)
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.activeLibraryTrackList
                    verticalPolicy: ScrollBar.AsNeeded
                    horizontalPolicy: ScrollBar.AlwaysOff
                    reserveScrollbarSpace: false
                    gradientColor: Color.mSurfaceVariant

                    delegate: Item {
                      width: libraryTrackList.availableWidth
                      implicitHeight: libraryTrackCard.implicitHeight

                      TrackCard {
                        id: libraryTrackCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        entry: modelData
                        section: "library"
                      }
                    }
                  }

                  NText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    visible: !root.hasLibrarySelection() && root.librarySection === "playlists" && root.filteredPlaylistEntries.length === 0
                    text: pluginApi?.tr("panel.emptyPlaylists")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    wrapMode: Text.Wrap
                  }

                  NText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    visible: !root.hasLibrarySelection() && root.librarySection === "artists" && root.filteredArtistStats.length === 0
                    text: pluginApi?.tr("panel.emptyArtists")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    wrapMode: Text.Wrap
                  }

                  NText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    visible: !root.hasLibrarySelection() && root.librarySection === "tags" && root.filteredTagStats.length === 0
                    text: pluginApi?.tr("panel.emptyTags")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    wrapMode: Text.Wrap
                  }

                  NScrollView {
                    id: libraryBrowseScroll
                    anchors.fill: parent
                    visible: !root.hasLibrarySelection()
                        && root.librarySection !== "tracks"
                        && ((root.librarySection === "playlists" && root.filteredPlaylistEntries.length > 0)
                            || (root.librarySection === "artists" && root.filteredArtistStats.length > 0)
                            || (root.librarySection === "tags" && root.filteredTagStats.length > 0))
                    horizontalPolicy: ScrollBar.AlwaysOff
                    verticalPolicy: ScrollBar.AsNeeded
                    reserveScrollbarSpace: false
                    gradientColor: Color.mSurfaceVariant
                    bottomPadding: Style.marginS

                    ColumnLayout {
                      width: libraryBrowseScroll.availableWidth
                      spacing: Style.marginM

                      Repeater {
                        model: root.librarySection === "playlists" ? root.filteredPlaylistEntries : []

                        delegate: LibraryBrowseCard {
                          title: modelData?.name || pluginApi?.tr("playlists.untitled")
                          description: {
                            var parts = [pluginApi?.tr("playlists.trackCount", {"count": root.playlistEntryCount(modelData)})];
                            var sourceFolder = String(modelData?.sourceFolder || "").trim();
                            if (sourceFolder.length > 0) {
                              parts.push(sourceFolder);
                            }
                            return parts.join(" • ");
                          }
                          accentText: String(root.playlistEntryCount(modelData))
                          iconText: "\u266b"
                          primaryAction: ({
                                            "text": pluginApi?.tr("panel.openAction"),
                                            "icon": "folder-open",
                                            "onClicked": function () {
                                              root.openPlaylistSection(modelData?.id || "");
                                            }
                                          })
                          secondaryAction: ({
                                              "text": pluginApi?.tr("panel.playAction"),
                                              "icon": "player-play-filled",
                                              "onClicked": function () {
                                                root.mainInstance?.playPlaylist(modelData?.id || "", false);
                                              }
                                            })
                          tertiaryAction: ({
                                             "text": pluginApi?.tr("panel.shuffleAction"),
                                             "icon": "arrows-shuffle",
                                             "onClicked": function () {
                                               root.mainInstance?.playPlaylist(modelData?.id || "", true);
                                             }
                                           })
                          quaternaryAction: ({
                                                "text": pluginApi?.tr("panel.queueAction"),
                                                "icon": "list",
                                                "onClicked": function () {
                                                  root.mainInstance?.queuePlaylist(modelData?.id || "", false);
                                                }
                                              })
                        }
                      }

                      Repeater {
                        model: root.librarySection === "artists" ? root.filteredArtistStats : []

                        delegate: LibraryBrowseCard {
                          title: modelData?.name || ""
                          description: {
                            var parts = [pluginApi?.tr("library.trackCount", {"count": Number(modelData?.count || 0)})];
                            var plays = root.formatPlayCount(Number(modelData?.playCount || 0));
                            if (plays.length > 0) {
                              parts.push(plays);
                            }
                            return parts.join(" • ");
                          }
                          accentText: String(Number(modelData?.count || 0))
                          iconText: "\u25c9"
                          primaryAction: ({
                                            "text": pluginApi?.tr("panel.openAction"),
                                            "icon": "folder-open",
                                            "onClicked": function () {
                                              root.openArtistSection(modelData?.name || "");
                                            }
                                          })
                        }
                      }

                      Repeater {
                        model: root.librarySection === "tags" ? root.filteredTagStats : []

                        delegate: LibraryBrowseCard {
                          title: "#" + (modelData?.tag || "")
                          description: pluginApi?.tr("library.trackCount", {"count": Number(modelData?.count || 0)})
                          accentText: String(Number(modelData?.count || 0))
                          iconText: "#"
                          primaryAction: ({
                                            "text": pluginApi?.tr("panel.openAction"),
                                            "icon": "folder-open",
                                            "onClicked": function () {
                                              root.openTagSection(modelData?.tag || "");
                                            }
                                          })
                        }
                      }
                    }
                  }
                }
              }
            }

            Item {
              height: tabView.height

              ColumnLayout {
                anchors.fill: parent
                spacing: Style.marginM

                RowLayout {
                  Layout.fillWidth: true
                  spacing: root.panelCardSpacing
                  visible: root.showPanelQueueControls

                  NButton {
                    text: pluginApi?.tr("panel.startQueue")
                    icon: "player-play-filled"
                    fontSize: Style.fontSizeS
                    enabled: (mainInstance?.queueEntries || []).length > 0
                    onClicked: root.mainInstance?.startQueue()
                  }

                  NButton {
                    text: pluginApi?.tr("panel.skipQueue")
                    icon: "player-skip-forward"
                    fontSize: Style.fontSizeS
                    enabled: (mainInstance?.queueEntries || []).length > 0
                    onClicked: root.mainInstance?.skipQueue()
                  }

                  NButton {
                    text: pluginApi?.tr("panel.clearQueue")
                    icon: "trash"
                    fontSize: Style.fontSizeS
                    enabled: (mainInstance?.queueEntries || []).length > 0
                    onClicked: root.mainInstance?.clearQueue()
                  }

                  Item {
                    Layout.fillWidth: true
                  }
                }

                NText {
                  Layout.fillWidth: true
                  text: pluginApi?.tr("panel.queueCount", {"count": (mainInstance?.queueEntries || []).length})
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeS
                }

                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  Layout.bottomMargin: Style.marginS

                  NText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    visible: (mainInstance?.queueEntries || []).length === 0
                    text: pluginApi?.tr("panel.emptyQueue")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    wrapMode: Text.Wrap
                  }

                  NListView {
                    id: queueList
                    anchors.fill: parent
                    visible: (mainInstance?.queueEntries || []).length > 0
                    spacing: Style.marginM
                    cacheBuffer: Math.round(800 * Style.uiScaleRatio)
                    boundsBehavior: Flickable.StopAtBounds
                    model: mainInstance?.queueEntries || []
                    verticalPolicy: ScrollBar.AsNeeded
                    horizontalPolicy: ScrollBar.AlwaysOff
                    reserveScrollbarSpace: false
                    gradientColor: Color.mSurfaceVariant

                    delegate: Item {
                      width: queueList.availableWidth
                      implicitHeight: queueCard.implicitHeight

                      TrackCard {
                        id: queueCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        entry: modelData
                        section: "queue"
                      }
                    }
                  }
                }
              }
              }
            }

              NIconButton {
                visible: root.showPanelPreview && !root.panelPreviewItem && root.hasPlayback
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: -Math.round(baseSize * 0.35)
                z: 2
                icon: "chevron-left"
                tooltipText: pluginApi?.tr("panel.showPreview")
                baseSize: 26
                onClicked: root.syncPanelPlaybackPreview(true)
              }
            }

            Item {
              visible: root.showPanelPreview && !!root.panelPreviewItem
              Layout.preferredWidth: Math.round(10 * Style.uiScaleRatio)
              Layout.fillHeight: true

              Rectangle {
                width: Math.max(2, Math.round(3 * Style.uiScaleRatio))
                radius: width / 2
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: Style.marginM
                anchors.bottomMargin: Style.marginM
                color: splitterMouseArea.pressed
                    ? Qt.alpha(Color.mPrimary, 0.65)
                    : (splitterMouseArea.containsMouse
                        ? Qt.alpha(Color.mPrimary, 0.38)
                        : Qt.alpha((Color.mOutline || Color.mOnSurfaceVariant || "#888888"), 0.28))
              }

              MouseArea {
                id: splitterMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor

                property real dragStartX: 0
                property real dragStartWidth: 0

                onPressed: mouse => {
                             dragStartX = splitterMouseArea.mapToItem(panelTabsRow, mouse.x, mouse.y).x;
                             dragStartWidth = root.previewPaneWidth;
                           }

                onPositionChanged: mouse => {
                                     if (!pressed) {
                                       return;
                                     }
                                     var currentX = splitterMouseArea.mapToItem(panelTabsRow, mouse.x, mouse.y).x;
                                     root.persistPreviewPaneWidth(dragStartWidth - (currentX - dragStartX), false);
                                   }

                onReleased: root.persistPreviewPaneWidth(root.previewPaneWidth, true)
              }
            }

            Rectangle {
              id: previewPane
              visible: root.showPanelPreview && !!root.panelPreviewItem
              Layout.preferredWidth: root.previewPaneWidth > 0
                  ? root.previewPaneWidth
                  : root.clampPreviewPaneWidth(Math.round(panelTabsRow.width * 0.34))
              Layout.maximumWidth: root.previewPaneMaxWidthCap
              Layout.fillHeight: true
              radius: root.panelCardRadius
              color: Qt.alpha(Color.mSurface, 0.55)
              border.width: Style.borderS
              border.color: Qt.alpha((Color.mOutline || Color.mOnSurfaceVariant || "#888888"), 0.24)
              clip: true
              readonly property bool showPreviewPlaybackActions: !root.showPanelNowPlaying
                  && root.hasPlayback
                  && root.previewItemsEqual(root.panelPreviewItem, root.playbackPreviewEntry())

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginS

                RowLayout {
                  id: previewHeader
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  Item {
                    Layout.fillWidth: true
                  }

                  NIconButton {
                    icon: "x"
                    tooltipText: pluginApi?.tr("panel.hidePreview")
                    baseSize: 28
                    onClicked: root.clearPanelPreview()
                  }
                }

                MusicPreview {
                  id: panelPreview
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  currentItem: root.panelPreviewItem
                  showChips: false
                  showLengthDetails: false
                  showPlaybackProgress: !(root.showPanelNowPlaying && root.showPanelPlaybackProgress)
                  showInlineSpeedControls: previewPane.showPreviewPlaybackActions
                }

                Flow {
                  Layout.fillWidth: true
                  visible: previewPane.showPreviewPlaybackActions
                  width: parent.width
                  spacing: Style.marginS

                  NButton {
                    text: mainInstance?.isPaused === true ? pluginApi?.tr("panel.resume") : pluginApi?.tr("panel.pause")
                    icon: mainInstance?.isPaused === true ? "player-play-filled" : "player-pause-filled"
                    fontSize: Style.fontSizeS
                    enabled: mainInstance?.isPlaying === true
                    onClicked: mainInstance?.togglePause()
                  }

                  NButton {
                    text: pluginApi?.tr("panel.stop")
                    icon: "player-stop-filled"
                    fontSize: Style.fontSizeS
                    enabled: root.hasPlayback
                    onClicked: mainInstance?.stopPlayback()
                  }
                }

                NText {
                  id: previewPlaybackStatus
                  Layout.fillWidth: true
                  visible: previewPane.showPreviewPlaybackActions
                      && mainInstance?.playbackStarting === true
                      && text.length > 0
                  text: (mainInstance?.playbackStartingMessage || "").trim()
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeS
                  wrapMode: Text.NoWrap
                  elide: Text.ElideRight
                }

                Flow {
                  Layout.fillWidth: true
                  visible: previewPane.showPreviewPlaybackActions
                  width: parent.width
                  spacing: Style.marginS

                  NButton {
                    text: pluginApi?.tr("panel.saveCurrent")
                    icon: "bookmark-plus"
                    fontSize: Style.fontSizeS
                    enabled: root.hasPlayback && mainInstance?.findSavedEntry({
                                                           "id": mainInstance?.currentEntryId || "",
                                                           "url": mainInstance?.currentUrl || ""
                                                         }) === null
                    onClicked: mainInstance?.saveEntry({
                                                         "id": mainInstance?.currentEntryId || "",
                                                         "title": mainInstance?.currentTitle || "",
                                                         "url": mainInstance?.currentUrl || "",
                                                         "uploader": mainInstance?.currentUploader || "",
                                                         "duration": mainInstance?.currentDuration || 0,
                                                         "provider": mainInstance?.currentProvider || ""
                                                       })
                  }

                  NButton {
                    text: pluginApi?.tr("panel.saveCurrentMp3")
                    icon: "download"
                    fontSize: Style.fontSizeS
                    enabled: root.hasPlayback && root.isRemoteEntry({
                                                     "url": mainInstance?.currentUrl || "",
                                                     "provider": mainInstance?.currentProvider || ""
                                                   })
                    onClicked: mainInstance?.downloadCurrentTrack()
                  }

                  NButton {
                    text: pluginApi?.tr("panel.refresh")
                    icon: "refresh"
                    fontSize: Style.fontSizeS
                    onClicked: mainInstance?.refreshStatus(true)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
