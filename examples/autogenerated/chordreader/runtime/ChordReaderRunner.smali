.class public final LIdric/ChordReaderRunner;
.super Ljava/lang/Object;

# External ART oracle only. The candidate is compiled from AppPitch.idric and
# supplies every operation under test; this harness never replaces its code.
.method public static main([Ljava/lang/String;)V
    .registers 6
    const/4 v0, 0x0
    :pitch_loop
    add-int/lit8 v1, v0, 0x1
    rem-int/lit8 v1, v1, 0xc
    invoke-static {v0}, LIdric/Generated;->pitch_up(I)I
    move-result v3
    if-ne v1, v3, :fail
    add-int/lit8 v2, v0, 0xb
    rem-int/lit8 v2, v2, 0xc
    invoke-static {v0}, LIdric/Generated;->pitch_down(I)I
    move-result v3
    if-ne v2, v3, :fail
    add-int/lit8 v0, v0, 0x1
    const/16 v4, 0xc
    if-lt v0, v4, :pitch_loop

    const/4 v0, -0x1
    invoke-static {v0}, LIdric/Generated;->pitch_up(I)I
    move-result v1
    if-ne v0, v1, :fail
    invoke-static {v0}, LIdric/Generated;->pitch_down(I)I
    move-result v1
    if-ne v0, v1, :fail
    const/16 v2, 0xc
    invoke-static {v2}, LIdric/Generated;->pitch_up(I)I
    move-result v1
    if-ne v0, v1, :fail
    invoke-static {v2}, LIdric/Generated;->pitch_down(I)I
    move-result v1
    if-ne v0, v1, :fail

    const-string v0, "#"
    const-string v1, "♯"
    invoke-static {v0}, LIdric/Generated;->accidental_symbol(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "b"
    const-string v1, "♭"
    invoke-static {v0}, LIdric/Generated;->accidental_symbol(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "♯"
    invoke-static {v0}, LIdric/Generated;->accidental_symbol(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "𝄪"
    invoke-static {v0}, LIdric/Generated;->accidental_symbol(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "A/C♯"
    invoke-static {v0}, LIdric/Generated;->accidental_symbol(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS ChordReader checked DEX: 24 pitch steps, 4 invalid inputs, 5 Unicode/alias cases"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
    :fail
    new-instance v0, Ljava/lang/IllegalStateException;
    const-string v1, "FAIL ChordReader checked DEX operation"
    invoke-direct {v0, v1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V
    throw v0
.end method
