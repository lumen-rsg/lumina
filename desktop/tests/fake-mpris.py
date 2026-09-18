#!/usr/bin/python3
"""Isolated session-bus media player for the real Quickshell MPRIS fixture."""
import json
import sys
from pathlib import Path
from gi.repository import Gio, GLib

base = 'org.mpris.MediaPlayer2'
player = base + '.Player'
path = '/org/mpris/MediaPlayer2'
log = []
props = {
    base: {'Identity': GLib.Variant('s', 'Lumina QA Player'), 'CanQuit': GLib.Variant('b', True),
           'CanRaise': GLib.Variant('b', False), 'HasTrackList': GLib.Variant('b', False),
           'DesktopEntry': GLib.Variant('s', 'lumina-qa'), 'SupportedUriSchemes': GLib.Variant('as', []),
           'SupportedMimeTypes': GLib.Variant('as', [])},
    player: {'PlaybackStatus': GLib.Variant('s', 'Paused'), 'Rate': GLib.Variant('d', 1.0),
             'MinimumRate': GLib.Variant('d', 1.0), 'MaximumRate': GLib.Variant('d', 1.0),
             'Volume': GLib.Variant('d', 1.0), 'Position': GLib.Variant('x', 0),
             **{key: GLib.Variant('b', True) for key in ['CanControl', 'CanPlay', 'CanPause', 'CanSeek', 'CanGoNext', 'CanGoPrevious']}}
}

def metadata(title):
    return GLib.Variant('a{sv}', {'mpris:trackid': GLib.Variant('o', '/lumina/track1'),
        'mpris:length': GLib.Variant('x', 180000000), 'xesam:title': GLib.Variant('s', title),
        'xesam:artist': GLib.Variant('as', ['Cassiopeia'])})

props[player]['Metadata'] = metadata('First track')
methods = {base: '<method name="Quit"/><method name="Raise"/>', player:
    ''.join(f'<method name="{m}"/>' for m in ['Next', 'Previous', 'PlayPause', 'Play', 'Pause', 'Stop']) +
    '<method name="SetPosition"><arg type="o" direction="in"/><arg type="x" direction="in"/></method>' +
    '<method name="Seek"><arg type="x" direction="in"/></method><signal name="Seeked"><arg type="x"/></signal>'}
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
loop = GLib.MainLoop()

def changed(values):
    props[player].update(values)
    bus.emit_signal(None, path, 'org.freedesktop.DBus.Properties', 'PropertiesChanged', GLib.Variant('(sa{sv}as)', (player, values, [])))

def call(conn, sender, obj, iface, method, params, invocation):
    values = params.unpack()
    log.append([method, list(values)])
    Path(sys.argv[1]).write_text(json.dumps(log))
    if method == 'PlayPause': changed({'PlaybackStatus': GLib.Variant('s', 'Playing' if props[player]['PlaybackStatus'].unpack() == 'Paused' else 'Paused')})
    if method in ('Play', 'Pause', 'Stop'): changed({'PlaybackStatus': GLib.Variant('s', {'Play': 'Playing', 'Pause': 'Paused', 'Stop': 'Stopped'}[method])})
    if method == 'Next': changed({'Metadata': metadata('Next track')})
    if method == 'Previous': changed({'Metadata': metadata('Previous track'), 'CanGoNext': GLib.Variant('b', False)})
    if method in ('SetPosition', 'Seek'):
        position = values[-1]
        props[player]['Position'] = GLib.Variant('x', position)
        bus.emit_signal(None, path, player, 'Seeked', GLib.Variant('(x)', (position,)))
    invocation.return_value(GLib.Variant('()', ()))
    if method == 'Quit': GLib.idle_add(loop.quit)

for iface, values in props.items():
    xml = '<node><interface name="' + iface + '">' + methods[iface]
    xml += ''.join(f'<property name="{key}" type="{value.get_type_string()}" access="read"/>' for key, value in values.items())
    info = Gio.DBusNodeInfo.new_for_xml(xml + '</interface></node>')
    bus.register_object(path, info.interfaces[0], call, lambda conn, sender, obj, iface, prop: props[iface][prop], None)

owner = Gio.bus_own_name_on_connection(bus, base + '.lumina_qa', Gio.BusNameOwnerFlags.NONE, None, None)
loop.run()
Gio.bus_unown_name(owner)
