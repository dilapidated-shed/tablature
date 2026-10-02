package org.hollowbamboo.chordreader2.helper

import org.hollowbamboo.chordreader2.chords.Chord
import org.hollowbamboo.chordreader2.chords.ChordRoot

object TransposeHelper {

    @JvmStatic
    fun transposeChord(chord: Chord, capoFret: Int, transposeHalfSteps: Int): Chord {
        val Δ = capoFret - transposeHalfSteps
        val transposed = chord.clone()

        transposed.root = requireNotNull(transposed.root) + Δ
        transposed.overridingRoot = transposed.overridingRoot?.plus(Δ)

        return transposed
    }

    private operator fun ChordRoot.plus(Δ: Int): ChordRoot {
        val roots = ChordRoot.values()
        val shifted = (ordinal + Δ) % roots.size
        val wrapped = if (shifted < 0) shifted + roots.size else shifted
        return roots[wrapped]
    }
}
