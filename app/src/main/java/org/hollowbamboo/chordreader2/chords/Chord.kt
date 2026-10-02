package org.hollowbamboo.chordreader2.chords

import java.io.Serializable

data class Chord(
    var root: ChordRoot? = null,
    var quality: ChordQuality? = null,
    var seventh: ChordExtended? = null,
    var added: ChordAdded? = null,
    var suspended: ChordSuspended? = null,
    var overridingRoot: ChordRoot? = null,
) : Cloneable, Serializable {

    public override fun clone(): Chord = copy()

    fun toPrintableString(noteNaming: NoteNaming): String = buildString {
        append(noteNaming.getNames(requireNotNull(root)).first())
        append(
            seventh?.aliases?.first()
                ?: requireNotNull(quality).aliases.first()
        )
        added?.let { append(it.aliases.first()) }
        suspended?.let { append(it.aliases.first()) }
        overridingRoot?.let { append('/').append(noteNaming.getNames(it).first()) }
    }

    companion object {
        @JvmStatic
        fun newChord(
            root: ChordRoot?,
            quality: ChordQuality?,
            seventh: ChordExtended?,
            added: ChordAdded?,
            suspended: ChordSuspended?,
            overridingRoot: ChordRoot?,
        ): Chord = Chord(root, quality, seventh, added, suspended, overridingRoot)
    }
}
