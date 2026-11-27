package es.quienlopropone

import androidx.compose.runtime.compositionLocalOf

/**
 * Idiomas de la app. Los textos de la interfaz y «lo esencial» de cada propuesta se han
 * traducido con inteligencia artificial; el texto literal de los programas no se traduce.
 */
enum class Idioma(val codigo: String, val nombre: String) {
    ES("es", "Español"),
    CA("ca", "Català"),
    GL("gl", "Galego"),
    EU("eu", "Euskara"),
    OC("oc", "Aranés (occitan)"),
    EN("en", "English"),
}

val LocalTextos = compositionLocalOf<Textos> { TextosES }

fun textosDe(i: Idioma): Textos = when (i) {
    Idioma.ES -> TextosES
    Idioma.CA -> TextosCA
    Idioma.GL -> TextosGL
    Idioma.EU -> TextosEU
    Idioma.OC -> TextosOC
    Idioma.EN -> TextosEN
}

/** Todos los textos de la interfaz. */
abstract class Textos {
    abstract val idioma: Idioma
    // Selección de idioma
    abstract val elegirIdioma: String
    abstract val avisoIA: String
    abstract val continuar: String
    abstract val cambiarIdioma: String
    // Inicio
    abstract val titulo: String
    abstract fun subtitulo(partidos: String): String
    abstract val comoVer: String
    abstract val loEsencial: String
    abstract val textoLiteral: String
    abstract val explicaEsencial: String
    abstract val explicaLiteral: String
    abstract val modoAdivina: String
    abstract val modoAdivinaDesc: String
    abstract val jugar: String
    abstract val modoVF: String
    abstract val modoVFDesc: String
    abstract val elegirPartido: String
    abstract fun compartidasInicio(n: Int): String
    abstract val fuentes: String
    // Configuración V/F
    abstract val volver: String
    abstract val vfMitad: String
    abstract val paso1: String
    abstract val paso2: String
    abstract val eligeUnPartido: String
    abstract fun empezar(n: Int, p: Partido): String
    // Partida
    abstract val salir: String
    abstract fun aciertos(n: Int): String
    abstract fun pregunta(i: Int, total: Int): String
    abstract val deQuePartido: String
    abstract fun esPropuestaDe(p: Partido): String
    abstract val verdadero: String
    abstract val falso: String
    abstract val siguiente: String
    abstract val verResultado: String
    // Revelación
    abstract val correcto: String
    abstract val no: String
    abstract fun esDe(p: Partido): String
    abstract fun tambienLoPropone(p: Partido): String
    abstract fun programa(p: Partido): String
    abstract fun medida(n: Int, pagina: Int, seccion: String): String
    abstract val verTexto: String
    abstract val ocultarTexto: String
    abstract val tituloEnPrograma: String
    abstract val tituloEnProgramaTraducido: String
    abstract val textoOriginalCatalan: String
    abstract val sinDetalle: String
    abstract fun compartidaCon(ps: List<Partido>): String
    abstract val parecidas: String
    abstract fun medidaCorta(p: Partido, n: Int): String
    // Resultado
    abstract fun tituloResultado(modo: Modo, p: Partido?): String
    abstract fun mensaje(pct: Int): String
    abstract fun nuevoRecord(antes: Int): String
    abstract fun record(r: Int, total: Int): String
    abstract val primeraPartida: String
    abstract val jugarOtra: String
    abstract val menu: String
    abstract fun compartidasPartida(c: Int, total: Int): String
    abstract val repaso: String
    abstract fun tambien(siglas: String): String
    // Datos
    abstract val temas: Map<String, String>
    fun tema(es: String) = temas[es] ?: es
    abstract val subtituloVox: String
    abstract val autonomicasCyL: String

    /** Une nombres con la conjunción del idioma: «A, B y C». */
    protected fun unir(xs: List<String>, y: String) =
        if (xs.size <= 1) xs.joinToString() else xs.dropLast(1).joinToString(", ") + " $y " + xs.last()

    fun subtituloBoton(p: Partido) = if (p == Partido.VOX) subtituloVox else p.subtitulo
}

// =====================================================================================
object TextosES : Textos() {
    override val idioma = Idioma.ES
    override val elegirIdioma = "Elige el idioma"
    override val avisoIA = "⚠️ Aviso: los textos de la aplicación y los resúmenes de las propuestas se han traducido mediante inteligencia artificial y pueden contener errores o imprecisiones. El texto literal de cada programa se muestra siempre en su idioma original."
    override val continuar = "Continuar"
    override val cambiarIdioma = "Idioma"
    override val titulo = "¿Quién lo propone?"
    override fun subtitulo(partidos: String) = "Pon a prueba lo que sabes de los programas electorales: $partidos."
    override val comoVer = "Cómo ver las propuestas"
    override val loEsencial = "Lo esencial"
    override val textoLiteral = "Texto literal"
    override val explicaEsencial = "Cada propuesta se resume de forma neutral, sin la retórica del partido. El texto original se puede consultar al responder."
    override val explicaLiteral = "Se muestra el título tal como aparece en el programa (los de ERC y Junts, traducidos del catalán)."
    override val modoAdivina = "Adivina el partido"
    override val modoAdivinaDesc = "10 propuestas de todos los partidos, repartidas a partes iguales. Para cada una, elige quién la propone."
    override val jugar = "Jugar"
    override val modoVF = "¿Verdadero o falso?"
    override val modoVFDesc = "Elige un partido y responde si cada propuesta es suya o no. Tú decides cuántas: 10, 20 o 50."
    override val elegirPartido = "Elegir partido"
    override fun compartidasInicio(n: Int) = "🤝 $n propuestas coinciden en lo esencial con la de otro partido. En el juego, cualquiera de ellos cuenta como respuesta correcta."
    override val fuentes = "Fuentes: programas del PSOE, PP, Frente Amplio y ERC para las elecciones generales de 2026; propuestas publicadas en la web de Junts (junts.cat/propostes), y programa de VOX para las autonómicas de Castilla y León 2026. Los textos de ERC y Junts están traducidos del catalán. Faltan los programas de otros partidos porque todavía no se han publicado; se añadirán cuando estén disponibles."
    override val volver = "← Volver"
    override val vfMitad = "La mitad de las propuestas serán del partido que elijas y la otra mitad, del resto de partidos."
    override val paso1 = "1. Elige un partido"
    override val paso2 = "2. ¿Cuántas preguntas?"
    override val eligeUnPartido = "Elige un partido"
    override fun empezar(n: Int, p: Partido) = "Empezar: $n preguntas sobre ${p.sigla}"
    override val salir = "← Salir"
    override fun aciertos(n: Int) = "Aciertos: $n"
    override fun pregunta(i: Int, total: Int) = "Pregunta $i de $total"
    override val deQuePartido = "¿De qué partido es?"
    override fun esPropuestaDe(p: Partido) = "¿Es una propuesta ${de(p)}?"
    override val verdadero = "Verdadero"
    override val falso = "Falso"
    override val siguiente = "Siguiente"
    override val verResultado = "Ver resultado"
    override val correcto = "¡Correcto! "
    override val no = "¡No! "
    override fun esDe(p: Partido) = "Es ${de(p)}"
    override fun tambienLoPropone(p: Partido) = "${art(p).replaceFirstChar { it.uppercase() }} también lo propone"
    override fun programa(p: Partido) = when (p) {
        Partido.PSOE -> "programa «La fuerza de seguir avanzando» (elecciones generales 2026)"
        Partido.PP -> "programa «La Reconstrucción Nacional» (elecciones generales 2026)"
        Partido.VOX -> "programa «Un programa con sentido común» (autonómicas de Castilla y León 2026)"
        Partido.FA -> "programa electoral (elecciones generales 2026)"
        Partido.ERC -> "programa «Pel país. Per la gent. Pel futur.» (elecciones generales 2026)"
        Partido.JUNTS -> "propuestas publicadas en su web (elecciones generales 2026)"
    }
    override fun medida(n: Int, pagina: Int, seccion: String) =
        "Medida nº $n" + (if (pagina > 0) " · página $pagina" else "") + " · $seccion"
    override val verTexto = "Ver el texto completo"
    override val ocultarTexto = "Ocultar el texto completo"
    override val tituloEnPrograma = "Título en el programa:"
    override val tituloEnProgramaTraducido = "Título en el programa (traducido):"
    override val textoOriginalCatalan = "Texto original (en catalán):"
    override val sinDetalle = "El programa no añade más detalle."
    override fun compartidaCon(ps: List<Partido>) =
        "🤝 Propuesta compartida: " + unir(ps.map { art(it) }, "y") + " también lo " + (if (ps.size == 1) "propone" else "proponen")
    override val parecidas = "Propuestas parecidas en otros programas"
    override fun medidaCorta(p: Partido, n: Int) = "${p.sigla} · medida nº $n"
    override fun tituloResultado(modo: Modo, p: Partido?) =
        if (modo == Modo.ADIVINA) modoAdivina else "$modoVF · ${p!!.sigla}"
    override fun mensaje(pct: Int) = when {
        pct == 100 -> "¡Perfecto! Te sabes los programas."
        pct >= 80 -> "¡Muy bien!"
        pct >= 60 -> "Nada mal."
        pct >= 40 -> "Regular: hay propuestas que sorprenden."
        else -> "Los programas tienen más sorpresas de lo que parece."
    }
    override fun nuevoRecord(antes: Int) = "¡Nuevo récord! (antes: $antes)"
    override fun record(r: Int, total: Int) = "Récord: $r / $total"
    override val primeraPartida = "Primera partida con esta configuración"
    override val jugarOtra = "Jugar otra vez"
    override val menu = "Menú principal"
    override fun compartidasPartida(c: Int, total: Int) = "🤝 $c de estas $total propuestas las comparten varios partidos."
    override val repaso = "Repaso"
    override fun tambien(siglas: String) = "🤝 también $siglas"
    override val subtituloVox = "Castilla y León"
    override val autonomicasCyL = "Autonómicas de Castilla y León"
    override val temas = mapOf<String, String>()

    private fun art(p: Partido) = when (p) { Partido.PP -> "el PP"; Partido.PSOE -> "el PSOE"; else -> p.nombreCorto() }
    private fun de(p: Partido) = when (p) { Partido.PP -> "del PP"; Partido.PSOE -> "del PSOE"; else -> "de ${p.nombreCorto()}" }
}

/** Nombre breve para frases: sigla, salvo Frente Amplio, que se escribe entero. */
fun Partido.nombreCorto() = if (this == Partido.FA) "Frente Amplio" else sigla

// =====================================================================================
object TextosCA : Textos() {
    override val idioma = Idioma.CA
    override val elegirIdioma = "Tria l'idioma"
    override val avisoIA = "⚠️ Avís: els textos de l'aplicació i els resums de les propostes s'han traduït mitjançant intel·ligència artificial i poden contenir errors o imprecisions. El text literal de cada programa es mostra sempre en la seva llengua original."
    override val continuar = "Continua"
    override val cambiarIdioma = "Idioma"
    override val titulo = "Qui ho proposa?"
    override fun subtitulo(partidos: String) = "Posa a prova el que saps dels programes electorals: $partidos."
    override val comoVer = "Com veure les propostes"
    override val loEsencial = "L'essencial"
    override val textoLiteral = "Text literal"
    override val explicaEsencial = "Cada proposta es resumeix de manera neutral, sense la retòrica del partit. El text original es pot consultar en respondre."
    override val explicaLiteral = "Es mostra el títol tal com apareix al programa (en castellà, o traduït al castellà en el cas d'ERC i Junts)."
    override val modoAdivina = "Endevina el partit"
    override val modoAdivinaDesc = "10 propostes de tots els partits, repartides a parts iguals. Per a cadascuna, tria qui la proposa."
    override val jugar = "Juga"
    override val modoVF = "Vertader o fals?"
    override val modoVFDesc = "Tria un partit i respon si cada proposta és seva o no. Tu decideixes quantes: 10, 20 o 50."
    override val elegirPartido = "Tria un partit"
    override fun compartidasInicio(n: Int) = "🤝 $n propostes coincideixen en l'essencial amb la d'un altre partit. Al joc, qualsevol d'ells compta com a resposta correcta."
    override val fuentes = "Fonts: programes del PSOE, PP, Frente Amplio i ERC per a les eleccions generals del 2026; propostes publicades al web de Junts (junts.cat/propostes), i programa de VOX per a les autonòmiques de Castella i Lleó del 2026. Falten els programes d'altres partits perquè encara no s'han publicat; s'afegiran quan estiguin disponibles."
    override val volver = "← Enrere"
    override val vfMitad = "La meitat de les propostes seran del partit que triïs i l'altra meitat, de la resta de partits."
    override val paso1 = "1. Tria un partit"
    override val paso2 = "2. Quantes preguntes?"
    override val eligeUnPartido = "Tria un partit"
    override fun empezar(n: Int, p: Partido) = "Comença: $n preguntes sobre ${p.sigla}"
    override val salir = "← Surt"
    override fun aciertos(n: Int) = "Encerts: $n"
    override fun pregunta(i: Int, total: Int) = "Pregunta $i de $total"
    override val deQuePartido = "De quin partit és?"
    override fun esPropuestaDe(p: Partido) = "És una proposta ${de(p)}?"
    override val verdadero = "Vertader"
    override val falso = "Fals"
    override val siguiente = "Següent"
    override val verResultado = "Veure el resultat"
    override val correcto = "Correcte! "
    override val no = "No! "
    override fun esDe(p: Partido) = "És ${de(p)}"
    override fun tambienLoPropone(p: Partido) = "${art(p).replaceFirstChar { it.uppercase() }} també ho proposa"
    override fun programa(p: Partido) = when (p) {
        Partido.PSOE -> "programa «La fuerza de seguir avanzando» (eleccions generals 2026)"
        Partido.PP -> "programa «La Reconstrucción Nacional» (eleccions generals 2026)"
        Partido.VOX -> "programa «Un programa con sentido común» (autonòmiques de Castella i Lleó 2026)"
        Partido.FA -> "programa electoral (eleccions generals 2026)"
        Partido.ERC -> "programa «Pel país. Per la gent. Pel futur.» (eleccions generals 2026)"
        Partido.JUNTS -> "propostes publicades al seu web (eleccions generals 2026)"
    }
    override fun medida(n: Int, pagina: Int, seccion: String) =
        "Mesura núm. $n" + (if (pagina > 0) " · pàgina $pagina" else "") + " · $seccion"
    override val verTexto = "Veure el text complet"
    override val ocultarTexto = "Amagar el text complet"
    override val tituloEnPrograma = "Títol al programa:"
    override val tituloEnProgramaTraducido = "Títol al programa (traduït al castellà):"
    override val textoOriginalCatalan = "Text original (en català):"
    override val sinDetalle = "El programa no hi afegeix més detall."
    override fun compartidaCon(ps: List<Partido>) =
        "🤝 Proposta compartida: " + unir(ps.map { art(it) }, "i") + " també ho " + (if (ps.size == 1) "proposa" else "proposen")
    override val parecidas = "Propostes semblants en altres programes"
    override fun medidaCorta(p: Partido, n: Int) = "${p.sigla} · mesura núm. $n"
    override fun tituloResultado(modo: Modo, p: Partido?) =
        if (modo == Modo.ADIVINA) modoAdivina else "$modoVF · ${p!!.sigla}"
    override fun mensaje(pct: Int) = when {
        pct == 100 -> "Perfecte! Et saps els programes."
        pct >= 80 -> "Molt bé!"
        pct >= 60 -> "No està gens malament."
        pct >= 40 -> "Regular: hi ha propostes que sorprenen."
        else -> "Els programes tenen més sorpreses del que sembla."
    }
    override fun nuevoRecord(antes: Int) = "Nou rècord! (abans: $antes)"
    override fun record(r: Int, total: Int) = "Rècord: $r / $total"
    override val primeraPartida = "Primera partida amb aquesta configuració"
    override val jugarOtra = "Torna a jugar"
    override val menu = "Menú principal"
    override fun compartidasPartida(c: Int, total: Int) = "🤝 $c d'aquestes $total propostes les comparteixen diversos partits."
    override val repaso = "Repàs"
    override fun tambien(siglas: String) = "🤝 també $siglas"
    override val subtituloVox = "Castella i Lleó"
    override val autonomicasCyL = "Autonòmiques de Castella i Lleó"
    override val temas = mapOf(
        "Instituciones, democracia y justicia" to "Institucions, democràcia i justícia",
        "Administración pública y gasto público" to "Administració pública i despesa pública",
        "Autogobierno, modelo territorial y financiación" to "Autogovern, model territorial i finançament",
        "Lengua, cultura, memoria e identidad" to "Llengua, cultura, memòria i identitat",
        "Política exterior, Unión Europea y defensa" to "Política exterior, Unió Europea i defensa",
        "Seguridad, interior y emergencias" to "Seguretat, interior i emergències",
        "Inmigración, fronteras y nacionalidad" to "Immigració, fronteres i nacionalitat",
        "Vivienda" to "Habitatge",
        "Fiscalidad y finanzas públicas" to "Fiscalitat i finances públiques",
        "Economía, industria, trabajo y autónomos" to "Economia, indústria, treball i autònoms",
        "Pensiones, protección social, familias y cuidados" to "Pensions, protecció social, famílies i cures",
        "Igualdad, feminismo, LGTBI y antirracismo" to "Igualtat, feminisme, LGTBI i antiracisme",
        "Sanidad" to "Sanitat",
        "Educación, universidades e investigación" to "Educació, universitats i recerca",
        "Infraestructuras y transporte" to "Infraestructures i transport",
        "Energía, medio ambiente y agua" to "Energia, medi ambient i aigua",
        "Agricultura, pesca y mundo rural" to "Agricultura, pesca i món rural",
        "Sociedad digital e inteligencia artificial" to "Societat digital i intel·ligència artificial",
        "Bienestar animal" to "Benestar animal",
    )
    private fun art(p: Partido) = when (p) {
        Partido.PP -> "el PP"; Partido.PSOE -> "el PSOE"; Partido.FA -> "el Frente Amplio"; else -> p.sigla
    }
    private fun de(p: Partido) = when (p) {
        Partido.PP -> "del PP"; Partido.PSOE -> "del PSOE"; Partido.FA -> "del Frente Amplio"; Partido.ERC -> "d'ERC"; else -> "de ${p.sigla}"
    }
}

// =====================================================================================
object TextosGL : Textos() {
    override val idioma = Idioma.GL
    override val elegirIdioma = "Escolle o idioma"
    override val avisoIA = "⚠️ Aviso: os textos da aplicación e os resumos das propostas traducíronse mediante intelixencia artificial e poden conter erros ou imprecisións. O texto literal de cada programa móstrase sempre na súa lingua orixinal."
    override val continuar = "Continuar"
    override val cambiarIdioma = "Idioma"
    override val titulo = "Quen o propón?"
    override fun subtitulo(partidos: String) = "Pon a proba o que sabes dos programas electorais: $partidos."
    override val comoVer = "Como ver as propostas"
    override val loEsencial = "O esencial"
    override val textoLiteral = "Texto literal"
    override val explicaEsencial = "Cada proposta resúmese de forma neutral, sen a retórica do partido. O texto orixinal pódese consultar ao responder."
    override val explicaLiteral = "Móstrase o título tal e como aparece no programa (en castelán, ou traducido ao castelán no caso de ERC e Junts)."
    override val modoAdivina = "Adiviña o partido"
    override val modoAdivinaDesc = "10 propostas de todos os partidos, repartidas a partes iguais. Para cada unha, escolle quen a propón."
    override val jugar = "Xogar"
    override val modoVF = "Verdadeiro ou falso?"
    override val modoVFDesc = "Escolle un partido e responde se cada proposta é súa ou non. Ti decides cantas: 10, 20 ou 50."
    override val elegirPartido = "Escoller partido"
    override fun compartidasInicio(n: Int) = "🤝 $n propostas coinciden no esencial coa doutro partido. No xogo, calquera deles conta como resposta correcta."
    override val fuentes = "Fontes: programas do PSOE, PP, Frente Amplio e ERC para as eleccións xerais de 2026; propostas publicadas na web de Junts (junts.cat/propostes), e programa de VOX para as autonómicas de Castela e León 2026. Faltan os programas doutros partidos porque aínda non se publicaron; engadiranse cando estean dispoñibles."
    override val volver = "← Volver"
    override val vfMitad = "A metade das propostas serán do partido que escollas e a outra metade, do resto de partidos."
    override val paso1 = "1. Escolle un partido"
    override val paso2 = "2. Cantas preguntas?"
    override val eligeUnPartido = "Escolle un partido"
    override fun empezar(n: Int, p: Partido) = "Comezar: $n preguntas sobre ${p.sigla}"
    override val salir = "← Saír"
    override fun aciertos(n: Int) = "Acertos: $n"
    override fun pregunta(i: Int, total: Int) = "Pregunta $i de $total"
    override val deQuePartido = "De que partido é?"
    override fun esPropuestaDe(p: Partido) = "É unha proposta ${de(p)}?"
    override val verdadero = "Verdadeiro"
    override val falso = "Falso"
    override val siguiente = "Seguinte"
    override val verResultado = "Ver o resultado"
    override val correcto = "Correcto! "
    override val no = "Non! "
    override fun esDe(p: Partido) = "É ${de(p)}"
    override fun tambienLoPropone(p: Partido) = "${art(p).replaceFirstChar { it.uppercase() }} tamén o propón"
    override fun programa(p: Partido) = when (p) {
        Partido.PSOE -> "programa «La fuerza de seguir avanzando» (eleccións xerais 2026)"
        Partido.PP -> "programa «La Reconstrucción Nacional» (eleccións xerais 2026)"
        Partido.VOX -> "programa «Un programa con sentido común» (autonómicas de Castela e León 2026)"
        Partido.FA -> "programa electoral (eleccións xerais 2026)"
        Partido.ERC -> "programa «Pel país. Per la gent. Pel futur.» (eleccións xerais 2026)"
        Partido.JUNTS -> "propostas publicadas na súa web (eleccións xerais 2026)"
    }
    override fun medida(n: Int, pagina: Int, seccion: String) =
        "Medida n.º $n" + (if (pagina > 0) " · páxina $pagina" else "") + " · $seccion"
    override val verTexto = "Ver o texto completo"
    override val ocultarTexto = "Ocultar o texto completo"
    override val tituloEnPrograma = "Título no programa:"
    override val tituloEnProgramaTraducido = "Título no programa (traducido ao castelán):"
    override val textoOriginalCatalan = "Texto orixinal (en catalán):"
    override val sinDetalle = "O programa non engade máis detalle."
    override fun compartidaCon(ps: List<Partido>) =
        "🤝 Proposta compartida: " + unir(ps.map { art(it) }, "e") + " tamén o " + (if (ps.size == 1) "propón" else "propoñen")
    override val parecidas = "Propostas parecidas noutros programas"
    override fun medidaCorta(p: Partido, n: Int) = "${p.sigla} · medida n.º $n"
    override fun tituloResultado(modo: Modo, p: Partido?) =
        if (modo == Modo.ADIVINA) modoAdivina else "$modoVF · ${p!!.sigla}"
    override fun mensaje(pct: Int) = when {
        pct == 100 -> "Perfecto! Sabes os programas."
        pct >= 80 -> "Moi ben!"
        pct >= 60 -> "Nada mal."
        pct >= 40 -> "Regular: hai propostas que sorprenden."
        else -> "Os programas teñen máis sorpresas do que parece."
    }
    override fun nuevoRecord(antes: Int) = "Novo récord! (antes: $antes)"
    override fun record(r: Int, total: Int) = "Récord: $r / $total"
    override val primeraPartida = "Primeira partida con esta configuración"
    override val jugarOtra = "Xogar outra vez"
    override val menu = "Menú principal"
    override fun compartidasPartida(c: Int, total: Int) = "🤝 $c destas $total propostas compárteas máis dun partido."
    override val repaso = "Repaso"
    override fun tambien(siglas: String) = "🤝 tamén $siglas"
    override val subtituloVox = "Castela e León"
    override val autonomicasCyL = "Autonómicas de Castela e León"
    override val temas = mapOf(
        "Instituciones, democracia y justicia" to "Institucións, democracia e xustiza",
        "Administración pública y gasto público" to "Administración pública e gasto público",
        "Autogobierno, modelo territorial y financiación" to "Autogoberno, modelo territorial e financiamento",
        "Lengua, cultura, memoria e identidad" to "Lingua, cultura, memoria e identidade",
        "Política exterior, Unión Europea y defensa" to "Política exterior, Unión Europea e defensa",
        "Seguridad, interior y emergencias" to "Seguridade, interior e emerxencias",
        "Inmigración, fronteras y nacionalidad" to "Inmigración, fronteiras e nacionalidade",
        "Vivienda" to "Vivenda",
        "Fiscalidad y finanzas públicas" to "Fiscalidade e finanzas públicas",
        "Economía, industria, trabajo y autónomos" to "Economía, industria, traballo e autónomos",
        "Pensiones, protección social, familias y cuidados" to "Pensións, protección social, familias e coidados",
        "Igualdad, feminismo, LGTBI y antirracismo" to "Igualdade, feminismo, LGTBI e antirracismo",
        "Sanidad" to "Sanidade",
        "Educación, universidades e investigación" to "Educación, universidades e investigación",
        "Infraestructuras y transporte" to "Infraestruturas e transporte",
        "Energía, medio ambiente y agua" to "Enerxía, medio ambiente e auga",
        "Agricultura, pesca y mundo rural" to "Agricultura, pesca e mundo rural",
        "Sociedad digital e inteligencia artificial" to "Sociedade dixital e intelixencia artificial",
        "Bienestar animal" to "Benestar animal",
    )
    private fun art(p: Partido) = when (p) {
        Partido.PP -> "o PP"; Partido.PSOE -> "o PSOE"; Partido.FA -> "a Frente Amplio"; else -> p.sigla
    }
    private fun de(p: Partido) = when (p) {
        Partido.PP -> "do PP"; Partido.PSOE -> "do PSOE"; Partido.FA -> "da Frente Amplio"; else -> "de ${p.sigla}"
    }
}

// =====================================================================================
object TextosEU : Textos() {
    override val idioma = Idioma.EU
    override val elegirIdioma = "Aukeratu hizkuntza"
    override val avisoIA = "⚠️ Oharra: aplikazioaren testuak eta proposamenen laburpenak adimen artifizialaren bidez itzuli dira, eta akatsak edo zehaztasun-ezak izan ditzakete. Programa bakoitzaren testu literala jatorrizko hizkuntzan erakusten da beti."
    override val continuar = "Jarraitu"
    override val cambiarIdioma = "Hizkuntza"
    override val titulo = "Nork proposatzen du?"
    override fun subtitulo(partidos: String) = "Jarri proban hauteskunde-programei buruz dakizuna: $partidos."
    override val comoVer = "Nola ikusi proposamenak"
    override val loEsencial = "Funtsezkoa"
    override val textoLiteral = "Testu literala"
    override val explicaEsencial = "Proposamen bakoitza modu neutralean laburtzen da, alderdiaren erretorikarik gabe. Jatorrizko testua erantzutean kontsulta daiteke."
    override val explicaLiteral = "Izenburua programan agertzen den bezala erakusten da (gaztelaniaz, edo gaztelaniara itzulita ERC eta Junts-en kasuan)."
    override val modoAdivina = "Asmatu alderdia"
    override val modoAdivinaDesc = "Alderdi guztien 10 proposamen, zati berdinetan banatuta. Bakoitzean, aukeratu nork proposatzen duen."
    override val jugar = "Jokatu"
    override val modoVF = "Egia ala gezurra?"
    override val modoVFDesc = "Aukeratu alderdi bat eta erantzun proposamen bakoitza berea den ala ez. Zuk erabakitzen duzu zenbat: 10, 20 edo 50."
    override val elegirPartido = "Aukeratu alderdia"
    override fun compartidasInicio(n: Int) = "🤝 $n proposamen bat datoz funtsean beste alderdi baten batekin. Jokoan, edozein alderdi zuzentzat hartzen da."
    override val fuentes = "Iturriak: PSOE, PP, Frente Amplio eta ERCren programak 2026ko hauteskunde orokorretarako; Junts-ek bere webgunean argitaratutako proposamenak (junts.cat/propostes), eta VOXen programa Gaztela eta Leongo 2026ko autonomia-hauteskundeetarako. Beste alderdi batzuen programak falta dira, oraindik argitaratu ez direlako; eskuragarri daudenean gehituko dira."
    override val volver = "← Itzuli"
    override val vfMitad = "Proposamenen erdia aukeratzen duzun alderdiarenak izango dira, eta beste erdia gainerako alderdienak."
    override val paso1 = "1. Aukeratu alderdi bat"
    override val paso2 = "2. Zenbat galdera?"
    override val eligeUnPartido = "Aukeratu alderdi bat"
    override fun empezar(n: Int, p: Partido) = "Hasi: $n galdera ${p.sigla}-ri buruz"
    override val salir = "← Irten"
    override fun aciertos(n: Int) = "Asmatutakoak: $n"
    override fun pregunta(i: Int, total: Int) = "$i. galdera / $total"
    override val deQuePartido = "Zein alderdirena da?"
    override fun esPropuestaDe(p: Partido) = "${p.nombreCorto()}-(r)en proposamena da?"
    override val verdadero = "Egia"
    override val falso = "Gezurra"
    override val siguiente = "Hurrengoa"
    override val verResultado = "Ikusi emaitza"
    override val correcto = "Zuzena! "
    override val no = "Ez! "
    override fun esDe(p: Partido) = "${p.nombreCorto()}-(r)ena da"
    override fun tambienLoPropone(p: Partido) = "${p.nombreCorto()}-(e)k ere proposatzen du"
    override fun programa(p: Partido) = when (p) {
        Partido.PSOE -> "«La fuerza de seguir avanzando» programa (2026ko hauteskunde orokorrak)"
        Partido.PP -> "«La Reconstrucción Nacional» programa (2026ko hauteskunde orokorrak)"
        Partido.VOX -> "«Un programa con sentido común» programa (Gaztela eta Leongo 2026ko autonomia-hauteskundeak)"
        Partido.FA -> "hauteskunde-programa (2026ko hauteskunde orokorrak)"
        Partido.ERC -> "«Pel país. Per la gent. Pel futur.» programa (2026ko hauteskunde orokorrak)"
        Partido.JUNTS -> "bere webgunean argitaratutako proposamenak (2026ko hauteskunde orokorrak)"
    }
    override fun medida(n: Int, pagina: Int, seccion: String) =
        "$n. neurria" + (if (pagina > 0) " · $pagina. orrialdea" else "") + " · $seccion"
    override val verTexto = "Ikusi testu osoa"
    override val ocultarTexto = "Ezkutatu testu osoa"
    override val tituloEnPrograma = "Izenburua programan:"
    override val tituloEnProgramaTraducido = "Izenburua programan (gaztelaniara itzulita):"
    override val textoOriginalCatalan = "Jatorrizko testua (katalanez):"
    override val sinDetalle = "Programak ez du xehetasun gehiagorik ematen."
    override fun compartidaCon(ps: List<Partido>) =
        "🤝 Proposamen partekatua: " + unir(ps.map { it.nombreCorto() }, "eta") + "-(e)k ere proposatzen dute"
    override val parecidas = "Antzeko proposamenak beste programetan"
    override fun medidaCorta(p: Partido, n: Int) = "${p.sigla} · $n. neurria"
    override fun tituloResultado(modo: Modo, p: Partido?) =
        if (modo == Modo.ADIVINA) modoAdivina else "$modoVF · ${p!!.sigla}"
    override fun mensaje(pct: Int) = when {
        pct == 100 -> "Bikain! Programak ondo dakizkizu."
        pct >= 80 -> "Oso ondo!"
        pct >= 60 -> "Ez dago gaizki."
        pct >= 40 -> "Erdipurdi: badaude harritzen duten proposamenak."
        else -> "Programek dirudiena baino ezusteko gehiago dituzte."
    }
    override fun nuevoRecord(antes: Int) = "Errekor berria! (lehen: $antes)"
    override fun record(r: Int, total: Int) = "Errekorra: $r / $total"
    override val primeraPartida = "Konfigurazio honekin lehen partida"
    override val jugarOtra = "Jokatu berriro"
    override val menu = "Menu nagusia"
    override fun compartidasPartida(c: Int, total: Int) = "🤝 $total proposamen hauetatik $c alderdi batek baino gehiagok partekatzen ditu."
    override val repaso = "Errepasoa"
    override fun tambien(siglas: String) = "🤝 baita ere $siglas"
    override val subtituloVox = "Gaztela eta Leon"
    override val autonomicasCyL = "Gaztela eta Leongo autonomia-hauteskundeak"
    override val temas = mapOf(
        "Instituciones, democracia y justicia" to "Erakundeak, demokrazia eta justizia",
        "Administración pública y gasto público" to "Administrazio publikoa eta gastu publikoa",
        "Autogobierno, modelo territorial y financiación" to "Autogobernua, lurralde-eredua eta finantzaketa",
        "Lengua, cultura, memoria e identidad" to "Hizkuntza, kultura, memoria eta identitatea",
        "Política exterior, Unión Europea y defensa" to "Kanpo-politika, Europar Batasuna eta defentsa",
        "Seguridad, interior y emergencias" to "Segurtasuna, barnea eta larrialdiak",
        "Inmigración, fronteras y nacionalidad" to "Immigrazioa, mugak eta nazionalitatea",
        "Vivienda" to "Etxebizitza",
        "Fiscalidad y finanzas públicas" to "Fiskalitatea eta finantza publikoak",
        "Economía, industria, trabajo y autónomos" to "Ekonomia, industria, lana eta autonomoak",
        "Pensiones, protección social, familias y cuidados" to "Pentsioak, gizarte-babesa, familiak eta zaintzak",
        "Igualdad, feminismo, LGTBI y antirracismo" to "Berdintasuna, feminismoa, LGTBI eta antiarrazakeria",
        "Sanidad" to "Osasuna",
        "Educación, universidades e investigación" to "Hezkuntza, unibertsitateak eta ikerketa",
        "Infraestructuras y transporte" to "Azpiegiturak eta garraioa",
        "Energía, medio ambiente y agua" to "Energia, ingurumena eta ura",
        "Agricultura, pesca y mundo rural" to "Nekazaritza, arrantza eta landa-mundua",
        "Sociedad digital e inteligencia artificial" to "Gizarte digitala eta adimen artifiziala",
        "Bienestar animal" to "Animalien ongizatea",
    )
}

// =====================================================================================
object TextosOC : Textos() {
    override val idioma = Idioma.OC
    override val elegirIdioma = "Tria era lengua"
    override val avisoIA = "⚠️ Avís: es tèxtes dera aplicacion e es resums des prepauses s'an tradusit damb intelligéncia artificiau e pòden contier errors o imprecisions. Eth tèxte literau de cada programa se mòstre tostemps ena sua lengua originau."
    override val continuar = "Contunhar"
    override val cambiarIdioma = "Lengua"
    override val titulo = "Qui ac prepause?"
    override fun subtitulo(partidos: String) = "Mete a pròva çò que sabes des programes electoraus: $partidos."
    override val comoVer = "Coma veir es prepauses"
    override val loEsencial = "Er essenciau"
    override val textoLiteral = "Tèxte literau"
    override val explicaEsencial = "Cada prepausa se resumís de manèra neutrau, sense era retorica deth partit. Eth tèxte originau se pòt consultar en respóner."
    override val explicaLiteral = "Se mòstre eth títol tau coma apareish en programa (en castelhan, o tradusit en castelhan entà ERC e Junts)."
    override val modoAdivina = "Endevina eth partit"
    override val modoAdivinaDesc = "10 prepauses de toti es partits, repartides a parts egaus. Entà cada ua, tria qui la prepause."
    override val jugar = "Jogar"
    override val modoVF = "Vertadèr o faus?"
    override val modoVFDesc = "Tria un partit e respon se cada prepausa ei sua o non. Tu decides quantes: 10, 20 o 50."
    override val elegirPartido = "Tria un partit"
    override fun compartidasInicio(n: Int) = "🤝 $n prepauses coincidissen en çò d'essenciau damb era d'un aute partit. En jòc, quinsevolh d'eri compde coma responsa corrècta."
    override val fuentes = "Hònts: programes deth PSOE, PP, Frente Amplio e ERC entàs eleccions generaus de 2026; prepauses publicades ena web de Junts (junts.cat/propostes), e programa de VOX entàs autonomiques de Castelha e León 2026. Manquen es programes d'auti partits pr'amor que encara non s'an publicat; s'higeràn quan sigen disponibles."
    override val volver = "← Tornar"
    override val vfMitad = "Era mitat des prepauses seràn deth partit que trìes e era auta mitat, dera rèsta de partits."
    override val paso1 = "1. Tria un partit"
    override val paso2 = "2. Quantes question?"
    override val eligeUnPartido = "Tria un partit"
    override fun empezar(n: Int, p: Partido) = "Començar: $n questions sus ${p.sigla}"
    override val salir = "← Gésser"
    override fun aciertos(n: Int) = "Encèrts: $n"
    override fun pregunta(i: Int, total: Int) = "Question $i de $total"
    override val deQuePartido = "De quin partit ei?"
    override fun esPropuestaDe(p: Partido) = "Ei ua prepausa ${de(p)}?"
    override val verdadero = "Vertadèr"
    override val falso = "Faus"
    override val siguiente = "Seguent"
    override val verResultado = "Veir eth resultat"
    override val correcto = "Corrècte! "
    override val no = "Non! "
    override fun esDe(p: Partido) = "Ei ${de(p)}"
    override fun tambienLoPropone(p: Partido) = "${art(p).replaceFirstChar { it.uppercase() }} tanben ac prepause"
    override fun programa(p: Partido) = when (p) {
        Partido.PSOE -> "programa «La fuerza de seguir avanzando» (eleccions generaus 2026)"
        Partido.PP -> "programa «La Reconstrucción Nacional» (eleccions generaus 2026)"
        Partido.VOX -> "programa «Un programa con sentido común» (autonomiques de Castelha e León 2026)"
        Partido.FA -> "programa electorau (eleccions generaus 2026)"
        Partido.ERC -> "programa «Pel país. Per la gent. Pel futur.» (eleccions generaus 2026)"
        Partido.JUNTS -> "prepauses publicades ena sua web (eleccions generaus 2026)"
    }
    override fun medida(n: Int, pagina: Int, seccion: String) =
        "Mesura n. $n" + (if (pagina > 0) " · pagina $pagina" else "") + " · $seccion"
    override val verTexto = "Veir eth tèxte complet"
    override val ocultarTexto = "Amagar eth tèxte complet"
    override val tituloEnPrograma = "Títol en programa:"
    override val tituloEnProgramaTraducido = "Títol en programa (tradusit en castelhan):"
    override val textoOriginalCatalan = "Tèxte originau (en catalan):"
    override val sinDetalle = "Eth programa non i higé mès detalh."
    override fun compartidaCon(ps: List<Partido>) =
        "🤝 Prepausa compartida: " + unir(ps.map { art(it) }, "e") + " tanben ac " + (if (ps.size == 1) "prepause" else "prepausen")
    override val parecidas = "Prepauses semblantes en auti programes"
    override fun medidaCorta(p: Partido, n: Int) = "${p.sigla} · mesura n. $n"
    override fun tituloResultado(modo: Modo, p: Partido?) =
        if (modo == Modo.ADIVINA) modoAdivina else "$modoVF · ${p!!.sigla}"
    override fun mensaje(pct: Int) = when {
        pct == 100 -> "Perfècte! Te sabes es programes."
        pct >= 80 -> "Fòrça ben!"
        pct >= 60 -> "Non ei mau."
        pct >= 40 -> "Regular: i a prepauses que suspren."
        else -> "Es programes an mès suspreses de çò que semble."
    }
    override fun nuevoRecord(antes: Int) = "Nau record! (abans: $antes)"
    override fun record(r: Int, total: Int) = "Record: $r / $total"
    override val primeraPartida = "Prumèra partida damb aguesta configuracion"
    override val jugarOtra = "Tornar a jogar"
    override val menu = "Menú principau"
    override fun compartidasPartida(c: Int, total: Int) = "🤝 $c d'aguestes $total prepauses les compartissen diuèrsi partits."
    override val repaso = "Repàs"
    override fun tambien(siglas: String) = "🤝 tanben $siglas"
    override val subtituloVox = "Castelha e León"
    override val autonomicasCyL = "Autonomiques de Castelha e León"
    override val temas = mapOf(
        "Instituciones, democracia y justicia" to "Institucions, democràcia e justícia",
        "Administración pública y gasto público" to "Administracion publica e despensa publica",
        "Autogobierno, modelo territorial y financiación" to "Autogovèrn, modèl territoriau e finançament",
        "Lengua, cultura, memoria e identidad" to "Lengua, cultura, memòria e identitat",
        "Política exterior, Unión Europea y defensa" to "Politica exteriora, Union Europèa e defensa",
        "Seguridad, interior y emergencias" to "Seguretat, interior e emergéncies",
        "Inmigración, fronteras y nacionalidad" to "Immigracion, frontères e nacionalitat",
        "Vivienda" to "Habitatge",
        "Fiscalidad y finanzas públicas" to "Fiscalitat e finances publiques",
        "Economía, industria, trabajo y autónomos" to "Economia, indústria, trabalh e autonòms",
        "Pensiones, protección social, familias y cuidados" to "Pensions, proteccion sociau, families e suenhs",
        "Igualdad, feminismo, LGTBI y antirracismo" to "Egalitat, feminisme, LGTBI e antiracisme",
        "Sanidad" to "Sanitat",
        "Educación, universidades e investigación" to "Educacion, universitats e recèrca",
        "Infraestructuras y transporte" to "Infrastructures e transpòrt",
        "Energía, medio ambiente y agua" to "Energia, miei ambient e aigua",
        "Agricultura, pesca y mundo rural" to "Agricultura, pesca e mon rurau",
        "Sociedad digital e inteligencia artificial" to "Societat digitau e intelligéncia artificiau",
        "Bienestar animal" to "Benèster animau",
    )
    private fun art(p: Partido) = when (p) {
        Partido.PP -> "eth PP"; Partido.PSOE -> "eth PSOE"; Partido.FA -> "eth Frente Amplio"; else -> p.sigla
    }
    private fun de(p: Partido) = when (p) {
        Partido.PP -> "deth PP"; Partido.PSOE -> "deth PSOE"; Partido.FA -> "deth Frente Amplio"; Partido.ERC -> "d'ERC"; else -> "de ${p.sigla}"
    }
}

// =====================================================================================
object TextosEN : Textos() {
    override val idioma = Idioma.EN
    override val elegirIdioma = "Choose your language"
    override val avisoIA = "⚠️ Notice: the app's texts and the summaries of the proposals have been translated using artificial intelligence and may contain errors or inaccuracies. The literal text of each manifesto is always shown in its original language."
    override val continuar = "Continue"
    override val cambiarIdioma = "Language"
    override val titulo = "Who proposes it?"
    override fun subtitulo(partidos: String) = "Test what you know about the election manifestos: $partidos."
    override val comoVer = "How to show the proposals"
    override val loEsencial = "The gist"
    override val textoLiteral = "Literal text"
    override val explicaEsencial = "Each proposal is summarised neutrally, without the party's rhetoric. You can read the original text after answering."
    override val explicaLiteral = "The title is shown as it appears in the manifesto (in Spanish; ERC's and Junts' are translated from Catalan into Spanish)."
    override val modoAdivina = "Guess the party"
    override val modoAdivinaDesc = "10 proposals from all parties, evenly split. For each one, choose who proposes it."
    override val jugar = "Play"
    override val modoVF = "True or false?"
    override val modoVFDesc = "Pick a party and say whether each proposal is theirs or not. You choose how many: 10, 20 or 50."
    override val elegirPartido = "Choose a party"
    override fun compartidasInicio(n: Int) = "🤝 $n proposals essentially match one from another party. In the game, any of those parties counts as a correct answer."
    override val fuentes = "Sources: manifestos of PSOE, PP, Frente Amplio and ERC for the 2026 general election; proposals published on Junts' website (junts.cat/propostes), and VOX's manifesto for the 2026 Castile and León regional election. Other parties' manifestos are missing because they have not been published yet; they will be added when available."
    override val volver = "← Back"
    override val vfMitad = "Half of the proposals will be from the party you choose and the other half from the rest."
    override val paso1 = "1. Choose a party"
    override val paso2 = "2. How many questions?"
    override val eligeUnPartido = "Choose a party"
    override fun empezar(n: Int, p: Partido) = "Start: $n questions about ${p.sigla}"
    override val salir = "← Quit"
    override fun aciertos(n: Int) = "Correct: $n"
    override fun pregunta(i: Int, total: Int) = "Question $i of $total"
    override val deQuePartido = "Which party is it from?"
    override fun esPropuestaDe(p: Partido) = "Is this a ${p.nombreCorto()} proposal?"
    override val verdadero = "True"
    override val falso = "False"
    override val siguiente = "Next"
    override val verResultado = "See result"
    override val correcto = "Correct! "
    override val no = "No! "
    override fun esDe(p: Partido) = "It's from ${p.nombreCorto()}"
    override fun tambienLoPropone(p: Partido) = "${p.nombreCorto()} proposes it too"
    override fun programa(p: Partido) = when (p) {
        Partido.PSOE -> "manifesto «La fuerza de seguir avanzando» (2026 general election)"
        Partido.PP -> "manifesto «La Reconstrucción Nacional» (2026 general election)"
        Partido.VOX -> "manifesto «Un programa con sentido común» (2026 Castile and León regional election)"
        Partido.FA -> "election manifesto (2026 general election)"
        Partido.ERC -> "manifesto «Pel país. Per la gent. Pel futur.» (2026 general election)"
        Partido.JUNTS -> "proposals published on its website (2026 general election)"
    }
    override fun medida(n: Int, pagina: Int, seccion: String) =
        "Measure no. $n" + (if (pagina > 0) " · page $pagina" else "") + " · $seccion"
    override val verTexto = "Show full text"
    override val ocultarTexto = "Hide full text"
    override val tituloEnPrograma = "Title in the manifesto:"
    override val tituloEnProgramaTraducido = "Title in the manifesto (translated into Spanish):"
    override val textoOriginalCatalan = "Original text (in Catalan):"
    override val sinDetalle = "The manifesto gives no further detail."
    override fun compartidaCon(ps: List<Partido>) =
        "🤝 Shared proposal: " + unir(ps.map { it.nombreCorto() }, "and") + (if (ps.size == 1) " proposes it too" else " propose it too")
    override val parecidas = "Similar proposals in other manifestos"
    override fun medidaCorta(p: Partido, n: Int) = "${p.sigla} · measure no. $n"
    override fun tituloResultado(modo: Modo, p: Partido?) =
        if (modo == Modo.ADIVINA) modoAdivina else "$modoVF · ${p!!.sigla}"
    override fun mensaje(pct: Int) = when {
        pct == 100 -> "Perfect! You know the manifestos."
        pct >= 80 -> "Very good!"
        pct >= 60 -> "Not bad."
        pct >= 40 -> "So-so: some proposals are surprising."
        else -> "The manifestos hold more surprises than it seems."
    }
    override fun nuevoRecord(antes: Int) = "New record! (before: $antes)"
    override fun record(r: Int, total: Int) = "Record: $r / $total"
    override val primeraPartida = "First game with these settings"
    override val jugarOtra = "Play again"
    override val menu = "Main menu"
    override fun compartidasPartida(c: Int, total: Int) = "🤝 $c of these $total proposals are shared by more than one party."
    override val repaso = "Review"
    override fun tambien(siglas: String) = "🤝 also $siglas"
    override val subtituloVox = "Castile and León"
    override val autonomicasCyL = "Castile and León regional election"
    override val temas = mapOf(
        "Instituciones, democracia y justicia" to "Institutions, democracy and justice",
        "Administración pública y gasto público" to "Public administration and spending",
        "Autogobierno, modelo territorial y financiación" to "Self-government, territorial model and funding",
        "Lengua, cultura, memoria e identidad" to "Language, culture, memory and identity",
        "Política exterior, Unión Europea y defensa" to "Foreign policy, European Union and defence",
        "Seguridad, interior y emergencias" to "Security, home affairs and emergencies",
        "Inmigración, fronteras y nacionalidad" to "Immigration, borders and nationality",
        "Vivienda" to "Housing",
        "Fiscalidad y finanzas públicas" to "Taxation and public finances",
        "Economía, industria, trabajo y autónomos" to "Economy, industry, labour and self-employed",
        "Pensiones, protección social, familias y cuidados" to "Pensions, social protection, families and care",
        "Igualdad, feminismo, LGTBI y antirracismo" to "Equality, feminism, LGBTI and anti-racism",
        "Sanidad" to "Health",
        "Educación, universidades e investigación" to "Education, universities and research",
        "Infraestructuras y transporte" to "Infrastructure and transport",
        "Energía, medio ambiente y agua" to "Energy, environment and water",
        "Agricultura, pesca y mundo rural" to "Agriculture, fishing and rural areas",
        "Sociedad digital e inteligencia artificial" to "Digital society and artificial intelligence",
        "Bienestar animal" to "Animal welfare",
    )
}
