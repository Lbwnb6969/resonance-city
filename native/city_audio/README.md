CityPadMixer keeps score selection, stable group IDs, phases and DNA state in the existing model; it renders selected pad groups in one native block. GDScript remains the reference implementation and the backend for platforms without this extension.

Stereo accumulation is adapted from GDSiON SiOPMStream::write_from_vector at 00a3a6986cc248ee275cdb8ba2954816306759df; LICENSE-GDSiON retains both upstream notices. godot-cpp SDK is fixed to e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77 (godot-4.5-stable); its license is in LICENSE-godot-cpp. No GDSiON driver, score, voice stealing or oscillator replaces the city's music rules.

Windows x86_64 build: run tools/build_native_audio.ps1. Requires Git, Python and Visual Studio C++ Build Tools. Dependencies/build objects live under .git/任务备份/round120; the playable DLL is tracked under addons/city_audio/bin. Validate with tests/round120_native_audio.gd and real-output large-city testing.
