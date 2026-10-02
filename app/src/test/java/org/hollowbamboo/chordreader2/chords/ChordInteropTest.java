package org.hollowbamboo.chordreader2.chords;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotSame;
import static org.junit.Assert.assertNull;

import org.hollowbamboo.chordreader2.helper.TransposeHelper;
import org.junit.Test;

public class ChordInteropTest {

    @Test
    public void javaBeanSurfaceRemainsAvailable() {
        Chord chord = new Chord();

        chord.setRoot(ChordRoot.C);
        chord.setQuality(ChordQuality.Major);
        chord.setSeventh(ChordExtended.Major7);
        chord.setAdded(ChordAdded.Add9);
        chord.setSuspended(null);
        chord.setOverridingRoot(ChordRoot.G);

        assertEquals(ChordRoot.C, chord.getRoot());
        assertEquals(ChordQuality.Major, chord.getQuality());
        assertEquals(ChordExtended.Major7, chord.getSeventh());
        assertEquals(ChordAdded.Add9, chord.getAdded());
        assertNull(chord.getSuspended());
        assertEquals(ChordRoot.G, chord.getOverridingRoot());

        Chord cloned = chord.clone();
        assertEquals(chord, cloned);
        assertNotSame(chord, cloned);
    }

    @Test
    public void staticFactoryRemainsJavaCallable() {
        Chord chord = Chord.newChord(
                ChordRoot.D,
                ChordQuality.Minor,
                ChordExtended.Minor7,
                null,
                null,
                ChordRoot.A);

        assertEquals(ChordRoot.D, chord.getRoot());
        assertEquals(ChordQuality.Minor, chord.getQuality());
        assertEquals(ChordExtended.Minor7, chord.getSeventh());
        assertEquals(ChordRoot.A, chord.getOverridingRoot());
    }

    @Test
    public void transpositionDoesNotMutateTheInputAndWrapsBackward() {
        Chord chord = Chord.newChord(
                ChordRoot.C,
                ChordQuality.Major,
                null,
                null,
                null,
                ChordRoot.G);

        Chord transposed = TransposeHelper.transposeChord(chord, 0, 1);

        assertEquals(ChordRoot.C, chord.getRoot());
        assertEquals(ChordRoot.G, chord.getOverridingRoot());
        assertEquals(ChordRoot.B, transposed.getRoot());
        assertEquals(ChordRoot.Gb, transposed.getOverridingRoot());
    }
}
