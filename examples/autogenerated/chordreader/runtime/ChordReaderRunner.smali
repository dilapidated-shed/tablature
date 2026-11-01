.class public final LIdric/ChordReaderRunner;
.super Ljava/lang/Object;

# External ART oracle only. The candidate is compiled from ManagedCore.idric and
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

    const-string v0, "pA/C#"
    const-string v1, "1A/C♯"
    invoke-static {v0}, LIdric/Generated;->application_request(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "r1:11:14:A/C♯"
    const-string v1, "1B♭/D"
    invoke-static {v0}, LIdric/Generated;->application_request(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "c🧪 [A/C♯] la\n"
    const-string v1, "13\t7\t6\t12\t4\t8\tA/C♯\t9|C|1\n"
    invoke-static {v0}, LIdric/Generated;->application_request(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "k7:E major7:F major"
    const-string v1, "11\t1\tE major\tF major"
    invoke-static {v0}, LIdric/Generated;->application_request(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :fail
    const-string v0, "pAmazing"
    const-string v1, "0"
    invoke-static {v0}, LIdric/Generated;->application_request(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v2, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v3
    if-eqz v3, :fail

    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "PASS ChordReader checked DEX: 33 retained checks and 5 managed parser/chart/key checks"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void
    :fail
    sget-object v0, Ljava/lang/System;->out:Ljava/io/PrintStream;
    const-string v1, "FAIL ChordReader checked DEX operation"
    invoke-virtual {v0, v1}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/16 v0, 0x49
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method
