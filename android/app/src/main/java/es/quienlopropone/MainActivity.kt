package es.quienlopropone

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private const val TODAS = "Todas las categorías"

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val dark = isSystemInDarkTheme()
            MaterialTheme(colorScheme = if (dark) darkColorScheme() else lightColorScheme()) {
                Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    Juego()
                }
            }
        }
    }
}

fun colorDe(p: Partido): Color = when (p) {
    Partido.ERC -> Color(0xFFE8A317)
    Partido.PP -> Color(0xFF1D6FB8)
    Partido.VOX -> Color(0xFF4E9A23)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun Juego(respuestaInicial: Partido? = null) {
    val context = LocalContext.current
    val todas = remember { Repositorio.cargar(context) }
    val temas = remember { listOf(TODAS) + todas.map { it.tema }.distinct().sorted() }
    val prefs = remember { context.getSharedPreferences("marcador", Context.MODE_PRIVATE) }

    var tema by rememberSaveable { mutableStateOf(TODAS) }
    var mazo by rememberSaveable { mutableStateOf(barajar(todas, TODAS)) }
    var posicion by rememberSaveable { mutableIntStateOf(0) }
    var respuesta by rememberSaveable { mutableStateOf(respuestaInicial?.name) }
    var aciertos by rememberSaveable { mutableIntStateOf(0) }
    var jugadas by rememberSaveable { mutableIntStateOf(0) }
    var racha by rememberSaveable { mutableIntStateOf(0) }
    var mejorRacha by remember { mutableIntStateOf(prefs.getInt("mejorRacha", 0)) }
    var verDetalle by rememberSaveable { mutableStateOf(false) }

    val actual = todas[mazo[posicion]]

    fun siguiente() {
        respuesta = null
        verDetalle = false
        if (posicion + 1 < mazo.size) posicion++ else { mazo = barajar(todas, tema); posicion = 0 }
    }

    fun responder(p: Partido) {
        if (respuesta != null) return
        respuesta = p.name
        jugadas++
        if (p == actual.partido) {
            aciertos++; racha++
            if (racha > mejorRacha) { mejorRacha = racha; prefs.edit().putInt("mejorRacha", racha).apply() }
        } else racha = 0
    }

    Column(
        Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("¿Quién lo propone?", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(
            "Lee la propuesta y adivina de qué programa electoral es.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        // Marcador
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Marcador("Aciertos", "$aciertos / $jugadas")
            Marcador("Racha", "$racha")
            Marcador("Mejor racha", "$mejorRacha")
        }

        // Filtro por categoría
        var abierto by remember { mutableStateOf(false) }
        ExposedDropdownMenuBox(expanded = abierto, onExpandedChange = { abierto = it }) {
            OutlinedTextField(
                value = tema,
                onValueChange = {},
                readOnly = true,
                label = { Text("Categoría") },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = abierto) },
                modifier = Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable).fillMaxWidth(),
            )
            ExposedDropdownMenu(expanded = abierto, onDismissRequest = { abierto = false }) {
                temas.forEach { t ->
                    val n = if (t == TODAS) todas.size else todas.count { it.tema == t }
                    DropdownMenuItem(
                        text = { Text("$t ($n)") },
                        onClick = {
                            abierto = false
                            if (t != tema) {
                                tema = t; mazo = barajar(todas, t); posicion = 0
                                respuesta = null; verDetalle = false
                            }
                        },
                    )
                }
            }
        }

        // Tarjeta con la iniciativa
        ElevatedCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    "${actual.tema.uppercase()}  ·  ${posicion + 1} de ${mazo.size}",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                )
                Text(actual.titulo, fontSize = 21.sp, lineHeight = 28.sp, fontWeight = FontWeight.Medium)
            }
        }

        // Botones de respuesta
        Text("¿De qué partido es?", style = MaterialTheme.typography.titleMedium)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Partido.entries.forEach { p ->
                val elegido = respuesta == p.name
                Button(
                    onClick = { responder(p) },
                    enabled = respuesta == null || elegido || p == actual.partido,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = colorDe(p),
                        contentColor = Color.White,
                        disabledContainerColor = colorDe(p).copy(alpha = 0.25f),
                    ),
                    contentPadding = PaddingValues(horizontal = 4.dp, vertical = 8.dp),
                    modifier = Modifier.weight(1f).heightIn(min = 76.dp),
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(p.sigla, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                        Text(p.nombre, fontSize = 11.sp, lineHeight = 13.sp, textAlign = TextAlign.Center)
                    }
                }
            }
        }

        // Resultado
        AnimatedVisibility(visible = respuesta != null) {
            val acierto = respuesta == actual.partido.name
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (acierto) Color(0xFF2E7D32).copy(alpha = 0.15f) else Color(0xFFC62828).copy(alpha = 0.15f),
                ),
            ) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        if (acierto) "¡Correcto!" else "¡No! Es ${if (actual.partido == Partido.PP) "del" else "de"} ${actual.partido.sigla}",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = if (acierto) Color(0xFF2E7D32) else Color(0xFFC62828),
                    )
                    Text(
                        if (actual.partido == Partido.VOX) "VOX — programa ${actual.partido.programa}"
                        else "${actual.partido.nombre} (${actual.partido.sigla}) — programa ${actual.partido.programa}",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        "Medida nº ${actual.numero} · página ${actual.pagina} · ${actual.seccion}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    TextButton(onClick = { verDetalle = !verDetalle }, contentPadding = PaddingValues(0.dp)) {
                        Text(if (verDetalle) "Ocultar el texto completo" else "Ver el texto completo")
                    }
                    if (verDetalle) {
                        if (actual.original.isNotBlank()) {
                            Text("Texto original (en catalán):", style = MaterialTheme.typography.labelLarge)
                            Text(actual.original, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                        }
                        if (actual.descripcion.isNotBlank()) {
                            Text(actual.descripcion, style = MaterialTheme.typography.bodyMedium)
                        } else if (actual.original.isBlank()) {
                            Text("El programa no añade más detalle.", fontStyle = FontStyle.Italic)
                        }
                    }
                }
            }
        }

        Button(
            onClick = { siguiente() },
            enabled = respuesta != null,
            modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
        ) { Text("Siguiente propuesta", fontSize = 16.sp) }

        Text(
            "Fuentes: programas de ERC y PP para las elecciones generales de 2026 y de VOX para las " +
                "autonómicas de Castilla y León 2026 (parcial). Los títulos de ERC están traducidos del catalán.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun Marcador(etiqueta: String, valor: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(valor, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Text(etiqueta, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** Devuelve los índices de las iniciativas del tema, barajados (lista serializable para rememberSaveable). */
private fun barajar(todas: List<Iniciativa>, tema: String): ArrayList<Int> =
    ArrayList(todas.filter { tema == TODAS || it.tema == tema }.map { it.id }.shuffled())
