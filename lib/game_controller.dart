import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/catalog.dart';
import 'engine/game_engine.dart';
import 'models/event_models.dart';
import 'models/game_models.dart';
import 'theme/app_theme.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/save_service.dart';
import 'services/voice_over.dart';
import 'tour.dart';

enum AppView { boot, opening, title, newGame, load, play }

class GameController extends ChangeNotifier {
  GameController({
    SaveService? saves,
    AdsService? ads,
    IapService? iap,
    AudioService? audio,
  })  : saves = saves ?? SaveService(),
        ads = ads ?? AdsService(),
        iap = iap ?? IapService(),
        audio = audio ?? AudioService() {
    Palette.light = !darkMode;
    vo = VoiceOverService(this.audio);
  }

  final SaveService saves;
  final AdsService ads;
  final IapService iap;
  final AudioService audio;
  late final VoiceOverService vo;

  EventCatalog? catalog;
  GameEngine? engine;
  AppView view = AppView.boot;
  String? bootError;
  OutcomeDef? lastOutcome;
  EventDef? lastEvent;
  int hubIndex = 0;
  bool busy = false;
  String? toast;
  bool sfxOn = true;
  bool musicOn = true;
  bool darkMode = true;
  SharedPreferences? prefs;
  int coachStep = 0; // 0 see year, 1 choose, 2 next year, 3 done
  bool showHelp = false;
  bool showMoreStats = false;
  bool showSideSheet = false;

  bool yearFlash = false;
  Timer? _toastTimer;

  bool tourEnabled = true;
  bool tourActive = false;
  bool tourDone = false;
  bool openingSeen = false;
  int tourIndex = 0;
  final tourKeys = TourKeys();

  GameState get s => engine!.state;

  bool get playing => engine != null && view == AppView.play;

  Future<void> boot() async {
    try {
      try {
        prefs = await SharedPreferences.getInstance();
        sfxOn = prefs?.getBool('sfx') ?? true;
        musicOn = prefs?.getBool('music') ?? true;
        darkMode = prefs?.getBool('darkMode') ?? true;
        Palette.light = !darkMode;
        tourDone = prefs?.getBool('tourDone') ?? false;
        openingSeen = prefs?.getBool('openingSeen') ?? false;
        audio.sfxOn = sfxOn;
        audio.musicOn = musicOn;
        audio.sfxVolume = prefs?.getDouble('sfxVol') ?? 0.55;
        audio.musicVolume = prefs?.getDouble('musicVol') ?? 0.28;
        ads.adsRemoved = prefs?.getBool('adsRemoved') ?? false;
        audio.startMusic();
      } catch (_) {}
      catalog = await EventCatalog.loadFromAssets();
      await vo.preload();
      final splashFloor = DateTime.now().add(const Duration(milliseconds: 1400));
      final wait = splashFloor.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      view = openingSeen ? AppView.title : AppView.opening;
    } catch (e, st) {
      bootError = '$e';
      debugPrint('$e\n$st');
      view = openingSeen ? AppView.title : AppView.opening;
    }
    notifyListeners();
    unawaited(_initMonetization());
  }

  Future<void> finishOpening() async {
    await vo.stop();
    openingSeen = true;
    await prefs?.setBool('openingSeen', true);
    view = AppView.title;
    unawaited(audio.setBed('docks'));
    notifyListeners();
  }

  Future<void> replayOpening() async {
    view = AppView.opening;
    notifyListeners();
  }

  Future<void> _initMonetization() async {
    try {
      await ads.init();
    } catch (e) {
      debugPrint('ads init skipped: $e');
    }
    try {
      await iap.init();
    } catch (e) {
      debugPrint('iap init skipped: $e');
    }
  }

  Future<void> startNewGame({
    required String first,
    required String last,
    required String gender,
    required List<String> traits,
  }) async {
    if (catalog == null) return;
    engine = GameEngine.newGame(
      catalog: catalog!,
      firstName: first,
      lastName: last,
      gender: gender,
      traits: traits,
    );
    if (ads.adsRemoved) engine!.state.adsRemoved = true;
    view = AppView.play;
    hubIndex = 0;
    lastOutcome = null;
    coachStep = 0;
    showHelp = false;
    showMoreStats = false;
    showSideSheet = false;
    if (tourEnabled && !tourDone) {
      startTour(from: 0);
    }
    await persist();
    audio.card();
    audio.startMusic();
    notifyListeners();
    _syncBed();
  }

  void _syncBed() {
    final e = engine;
    unawaited(audio.setBed(e == null ? 'docks' : e.musicBed()));
  }

  Future<void> loadSlot(int slot) async {
    if (catalog == null) return;
    final st = await saves.read(slot);
    if (st == null) return;
    engine = GameEngine(state: st, catalog: catalog!);
    if (ads.adsRemoved) engine!.state.adsRemoved = true;
    view = AppView.play;
    hubIndex = 0;
    coachStep = st.tutorialDone ? 3 : 0;
    showHelp = false;
    showSideSheet = false;
    await persist(slot: 0);
    notifyListeners();
    _syncBed();
  }

  void goTitle() {
    unawaited(vo.stop());
    view = AppView.title;
    if (tourActive) {
      tourActive = false;
    }
    notifyListeners();
  }

  void goNew() {
    view = AppView.newGame;
    notifyListeners();
  }

  void goLoad() {
    view = AppView.load;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    unawaited(vo.disposePlayer());
    unawaited(audio.disposePlayers());
    super.dispose();
  }

  void setHub(int i) {
    hubIndex = i.clamp(0, 3);
    audio.tap();
    if (tourActive) {
      final a = Tour.steps[tourIndex].anchor;
      if ((a == TourAnchor.navFamily && i == 1) ||
          (a == TourAnchor.navCity && i == 2) ||
          (a == TourAnchor.navMore && i == 3)) {
        nextTour();
        return;
      }
    }
    notifyListeners();
  }

  /// Tap a highlighted More tile or a spotlight card during the tour.
  bool tourConsume(TourAnchor anchor) {
    if (!tourActive) return false;
    if (Tour.steps[tourIndex].anchor != anchor) return false;
    nextTour();
    return true;
  }

  void startTour({int from = 0}) {
    if (!tourEnabled) return;
    tourActive = true;
    tourIndex = from.clamp(0, Tour.length - 1);
    _alignHubToTour();
    notifyListeners();
  }

  void replayTour() {
    showHelp = false;
    startTour(from: 0);
  }

  void nextTour() {
    if (!tourActive) return;
    if (tourIndex >= Tour.length - 1) {
      skipTour();
      return;
    }
    tourIndex += 1;
    _alignHubToTour();
    notifyListeners();
  }

  void skipTour() {
    tourActive = false;
    tourDone = true;
    prefs?.setBool('tourDone', true);
    notifyListeners();
  }

  void _alignHubToTour() {
    if (view != AppView.play) return;
    final t = Tour.steps[tourIndex];
    if (t.hubIndex != null) hubIndex = t.hubIndex!;
  }

  GlobalKey? tourTargetKey() {
    if (!tourActive) return null;
    return Tour.steps[tourIndex].keyOf(tourKeys);
  }

  String get tourMeasureToken => [
        tourIndex,
        view,
        hubIndex,
        engine?.state.currentEventId,
        lastOutcome?.id,
        engine?.state.eventsThisYear,
        engine?.canAgeUp,
        engine?.yearEventPending,
      ].join('|');

  bool get coachActive => engine != null && coachStep < 3 && !s.tutorialDone;

  void openHelp() {
    showHelp = true;
    audio.tap();
    notifyListeners();
  }

  void closeHelp() {
    showHelp = false;
    notifyListeners();
  }

  void toggleMoreStats() {
    showMoreStats = !showMoreStats;
    notifyListeners();
  }

  void openSideSheet() {
    if (engine?.yearVerbUsed == true) {
      _flashToast('You already spent the year\'s move.');
      return;
    }
    showSideSheet = true;
    audio.tap();
    notifyListeners();
  }

  void closeSideSheet() {
    showSideSheet = false;
    notifyListeners();
  }

  Future<void> persist({int slot = 0}) async {
    final e = engine;
    if (e == null) return;
    await saves.write(slot, e.state);
  }

  Future<void> continueYear() async {
    final e = engine;
    if (e == null) return;
    if (e.yearEventPending) {
      await seeYear();
    } else {
      await nextYear();
    }
  }

  Future<void> seeYear() async {
    final e = engine;
    if (e == null || busy) return;
    if (e.state.awaitingHeir || e.state.phase == 'ending') {
      notifyListeners();
      return;
    }
    if (e.state.currentEventId != null) {
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    if (e.state.phase == 'summary') {
      e.state.phase = 'playing';
    }
    if (e.yearEventPending || e.extraBeatAvailable) {
      final ev = e.drawEvent();
      if (ev != null) {
        audio.card();
        yearFlash = false;
        if (coachStep == 0) coachStep = 1;
        if (tourActive && Tour.steps[tourIndex].anchor == TourAnchor.yearCta) {
          nextTour();
        }
        busy = false;
        notifyListeners();
        await persist();
        return;
      }
      if (e.state.eventsThisYear < 1) {
        e.state.eventsThisYear = 1;
      } else if (e.extraBeatAvailable) {
        e.state.eventsThisYear = 2;
      }
    }
    busy = false;
    notifyListeners();
  }

  Future<void> nextYear() async {
    final e = engine;
    if (e == null || busy) return;
    if (e.state.awaitingHeir || e.state.phase == 'ending') {
      notifyListeners();
      return;
    }
    if (e.state.currentEventId != null) {
      _flashToast('Finish the card first.');
      return;
    }
    if (!e.canAgeUp) {
      if (e.yearEventPending) {
        _flashToast('Open the year first.');
        return;
      }
      if (e.yearVerbRequired && !e.yearVerbUsed) {
        _flashToast('Work or a street first.');
        return;
      }
      if (e.extraBeatAvailable) {
        _flashToast('The city is not finished.');
        return;
      }
      _flashToast('Finish the card first.');
      return;
    }
    busy = true;
    notifyListeners();
    if (e.state.phase == 'summary') {
      e.state.phase = 'playing';
    }
    e.ageUp();
    e.state.tutorialDone = true;
    if (coachStep < 3) coachStep = 3;
    audio.year();
    yearFlash = true;
    hubIndex = 0;
    if (tourActive && Tour.steps[tourIndex].anchor == TourAnchor.nextYear) {
      nextTour();
    }
    busy = false;
    showSideSheet = false;
    await persist();
    notifyListeners();
    _syncBed();
    if (e.state.yearsSinceInterstitial >= 8 &&
        !e.state.inPrison &&
        e.state.currentEventId == null &&
        !e.state.awaitingHeir) {
      unawaited(ads.maybeInterstitial(
        reason: 'year',
        yearsSince: e.state.yearsSinceInterstitial,
      ).then((_) {
        e.state.yearsSinceInterstitial = 0;
      }));
    }
  }

  Future<void> doSide(String verb) async {
    final e = engine;
    if (e == null) return;
    showSideSheet = false;
    final id = e.simpleSideId(verb);
    if (id == null) return;
    if (e.state.activityUsed) {
      _flashToast('You already spent the year\'s move.');
      return;
    }
    final r = e.doActivity(id);
    if (r.skipped) {
      _flashToast('Not available right now.');
      return;
    }
    lastOutcome = r.outcome;
    lastEvent = r.event;
    final money = r.outcome.stats['money'] ?? 0;
    if ((r.outcome.stats['heat'] ?? 0) >= 8) {
      audio.heat();
    } else if (money != 0) {
      audio.money();
    } else {
      audio.success();
    }
    await persist();
    notifyListeners();
  }

  Future<void> choose(String id, {bool retry = false}) async {
    final e = engine;
    if (e == null) return;
    final r = e.choose(id, retry: retry);
    lastOutcome = r.outcome;
    lastEvent = r.event;
    final heat = r.outcome.stats['heat'] ?? 0;
    final money = r.outcome.stats['money'] ?? 0;
    if (r.outcome.isHarsh) {
      audio.fail();
    } else if (heat >= 8) {
      audio.heat();
    } else if (money != 0) {
      audio.money();
    } else {
      audio.confirm();
    }
    if (e.state.awaitingHeir) {
      unawaited(ads.maybeInterstitial(
        reason: e.state.heirReason == 'life sentence' || e.state.inPrison ? 'prison' : 'generation',
        yearsSince: e.state.yearsSinceInterstitial,
      ).then((_) {
        e.state.yearsSinceInterstitial = 0;
      }));
    }
    await persist();
    notifyListeners();
    _syncBed();
    if (tourActive && Tour.steps[tourIndex].anchor == TourAnchor.choice) {
      nextTour();
    }
  }

  Future<void> retryDecision() async {
    final e = engine;
    if (e == null || e.state.retryUsed || e.state.lastChoiceId == null) return;
    final ok = await ads.showRewarded(reason: 'retry');
    if (!ok) {
      _flashToast('Rewarded ad unavailable.');
      return;
    }
    // Restore last event and re-choose.
    if (e.state.lastEventId != null) {
      e.state.currentEventId = e.state.lastEventId;
    }
    await choose(e.state.lastChoiceId!, retry: true);
  }

  Future<void> bonusWhisper() async {
    final e = engine;
    if (e == null) return;
    final ok = await ads.showRewarded(reason: 'bonus');
    if (!ok) {
      _flashToast('Rewarded ad unavailable.');
      return;
    }
    e.state.stats.money += 400;
    e.state.stats.nerve = (e.state.stats.nerve + 1).clamp(0, 100);
    e.state.log('A whispered extra chance paid a small dividend.', category: 'life');
    audio.success();
    await persist();
    notifyListeners();
  }

  Future<void> pickHeir(String id) async {
    final heir = engine?.state.people[id];
    engine?.selectHeir(id);
    lastOutcome = OutcomeDef(
      id: 'heir_rise',
      title: heir == null ? 'The chair is yours' : '${heir.firstName} takes the chair',
      body: 'Money, turf, and enemies stay with the name. You sit where they sat. The rain does not care which generation.',
    );
    lastEvent = EventDef(id: 'heir_rise', title: lastOutcome!.title, body: '', category: 'legacy', art: 'legacy');
    unawaited(vo.play('heir_rise'));
    audio.legacy();
    yearFlash = true;
    hubIndex = 0;
    await persist();
    notifyListeners();
    _syncBed();
  }

  Future<void> openActivity(String id) async {
    final e = engine;
    if (e == null) return;
    if (e.openActivity(id)) {
      audio.card();
      await persist();
      notifyListeners();
    } else {
      _flashToast(e.state.activityUsed ? 'You already spent the year\'s move.' : 'Not available.');
    }
  }

  void dismissOutcome() {
    lastOutcome = null;
    lastEvent = null;
    unawaited(vo.stop());
    engine?.lastUnlocks = [];
    final e = engine;
    if (e != null && coachStep == 1 && e.canAgeUp) {
      coachStep = 2;
    }
    if (tourActive &&
        (Tour.steps[tourIndex].anchor == TourAnchor.outcome ||
            Tour.steps[tourIndex].anchor == TourAnchor.choice ||
            Tour.steps[tourIndex].anchor == TourAnchor.familyTree)) {
      nextTour();
    }
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    darkMode = !darkMode;
    Palette.light = !darkMode;
    await prefs?.setBool('darkMode', darkMode);
    notifyListeners();
  }

  Future<void> toggleSfx() async {
    sfxOn = !sfxOn;
    audio.setSfxOn(sfxOn);
    await prefs?.setBool('sfx', sfxOn);
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    musicOn = !musicOn;
    await audio.setMusicOn(musicOn);
    await prefs?.setBool('music', musicOn);
    notifyListeners();
  }

  Future<void> setMusicVol(double v) async {
    await audio.setMusicVolume(v);
    await prefs?.setDouble('musicVol', audio.musicVolume);
    notifyListeners();
  }

  Future<void> setSfxVol(double v) async {
    await audio.setSfxVolume(v);
    await prefs?.setDouble('sfxVol', audio.sfxVolume);
    notifyListeners();
  }

  Future<void> grantRemoveAds({bool fromStore = false}) async {
    ads.adsRemoved = true;
    engine?.state.adsRemoved = true;
    await prefs?.setBool('adsRemoved', true);
    await persist();
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    final ok = await iap.buy();
    if (ok) {
      await grantRemoveAds(fromStore: true);
    } else if (kDebugMode) {
      await grantRemoveAds();
      _flashToast('Remove Ads granted (debug / catalog empty).');
    } else {
      _flashToast('Store unavailable. Sideloaded builds can use the debug grant in Settings.');
    }
  }

  void clearToast() {
    toast = null;
  }

  void _flashToast(String msg) {
    toast = msg;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      toast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _ledger(String? Function() fn, {bool moneySfx = true}) async {
    final e = engine;
    if (e == null) return;
    final err = fn();
    if (err != null) {
      _flashToast(err);
      return;
    }
    if (moneySfx) {
      audio.money();
    } else {
      audio.success();
    }
    await persist();
    notifyListeners();
  }

  Future<void> dismissEnding() async {
    engine?.dismissEnding();
    await persist();
    notifyListeners();
  }

  Future<void> hireHand([String? role]) => _ledger(() => engine!.hireHand(role));
  Future<void> buyFront([String? type]) => _ledger(() => engine!.buyFront(type));
  Future<void> payBonus(String id) => _ledger(() => engine!.payBonus(id));
  Future<void> bumpCut(String id) => _ledger(() => engine!.bumpCut(id), moneySfx: false);
  Future<void> letGo(String id) => _ledger(() => engine!.letGo(id), moneySfx: false);
  Future<void> investFront(String id) => _ledger(() => engine!.investFront(id));
  Future<void> pressTurf(String id) async {
    final e = engine;
    if (e == null) return;
    await _ledger(() => e.pressTurf(id));
    tourConsume(TourAnchor.cityDistrict);
    final msg = e.lastPressResult;
    if (msg != null) _flashToast(msg);
  }
  Future<void> coolTurf(String id) async {
    await _ledger(() => engine!.coolTurf(id));
    tourConsume(TourAnchor.cityDistrict);
  }

  Future<void> squeezeTurf(String id) async {
    final e = engine;
    if (e == null) return;
    await _ledger(() => e.squeezeTurf(id));
    tourConsume(TourAnchor.cityDistrict);
    final msg = e.lastPressResult;
    if (msg != null) _flashToast(msg);
  }

  Future<void> quietTurf(String id) async {
    final e = engine;
    if (e == null) return;
    await _ledger(() => e.quietTurf(id));
    tourConsume(TourAnchor.cityDistrict);
    final msg = e.lastPressResult;
    if (msg != null) _flashToast(msg);
  }

  Future<void> tributeTurf(String id) async {
    final e = engine;
    if (e == null) return;
    await _ledger(() => e.tributeTurf(id));
    tourConsume(TourAnchor.cityDistrict);
    final msg = e.lastPressResult;
    if (msg != null) _flashToast(msg);
  }
  Future<void> sitWith(String id) async {
    final e = engine;
    if (e == null) return;
    final err = e.sitWith(id);
    if (err != null) {
      _flashToast(err);
      return;
    }
    final p = e.state.people[id];
    if (p != null) {
      lastOutcome = e.sitScene(p);
      lastEvent = EventDef(id: 'sit', title: lastOutcome!.title, body: lastOutcome!.body, category: 'family', art: 'sit');
    }
    audio.confirm();
    await persist();
    notifyListeners();
  }
  Future<void> giftPerson(String id) async {
    final e = engine;
    if (e == null) return;
    final err = e.giftPerson(id);
    if (err != null) {
      _flashToast(err);
      return;
    }
    audio.money();
    tourConsume(TourAnchor.familyTree);
    await persist();
    notifyListeners();
  }
  Future<void> assignCrew(String id, [String? bizId]) => _ledger(() => engine!.assignCrew(id, bizId), moneySfx: false);
}
