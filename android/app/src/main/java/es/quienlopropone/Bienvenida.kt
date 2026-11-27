package es.quienlopropone

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

/**
 * Pantallas de bienvenida: qué es la app y una por cada modo de juego.
 * Se muestran la primera vez y se pueden volver a abrir con el botón de ayuda.
 */
@Composable
fun Bienvenida(paginaInicial: Int = 0, onTerminar: () -> Unit) {
    val t = LocalTextos.current
    val paginas = t.bienvenida
    val estado = rememberPagerState(initialPage = paginaInicial) { paginas.size }
    val scope = rememberCoroutineScope()
    val ultima = estado.currentPage == paginas.lastIndex

    Column(
        Modifier.fillMaxSize().systemBarsPadding().padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            if (!ultima) TextButton(onClick = onTerminar) { Text(t.saltar) } else Spacer(Modifier.height(48.dp))
        }
        HorizontalPager(estado, Modifier.weight(1f).fillMaxWidth()) { i ->
            Column(
                Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Box(Modifier.height(260.dp).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    when (i) {
                        0 -> IlustracionApp()
                        1 -> IlustracionAdivina()
                        else -> IlustracionVF()
                    }
                }
                Spacer(Modifier.height(28.dp))
                Text(
                    paginas[i].first, style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold, textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    paginas[i].second, style = MaterialTheme.typography.bodyLarge,
                    textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        // Indicador de página
        Row(Modifier.padding(vertical = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            repeat(paginas.size) { i ->
                val activo = i == estado.currentPage
                Box(
                    Modifier
                        .size(width = if (activo) 24.dp else 8.dp, height = 8.dp)
                        .background(
                            if (activo) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                            CircleShape,
                        ),
                )
            }
        }
        Button(
            onClick = { if (ultima) onTerminar() else scope.launch { estado.animateScrollToPage(estado.currentPage + 1) } },
            modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
        ) { Text(if (ultima) t.empezarApp else t.siguiente, fontSize = 16.sp) }
    }
}

// ------------------------------------------------------------------ Ilustraciones

/** Tarjeta de propuesta en miniatura: unas líneas de «texto». */
@Composable
private fun TarjetaMini(ancho: Dp, lineas: Int = 3, modifier: Modifier = Modifier) {
    Surface(
        modifier.width(ancho),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        shadowElevation = 6.dp,
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(Modifier.width(ancho * 0.35f).height(8.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.6f), CircleShape))
            repeat(lineas) { i ->
                Box(
                    Modifier
                        .fillMaxWidth(if (i == lineas - 1) 0.6f else 1f)
                        .height(10.dp)
                        .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.25f), CircleShape),
                )
            }
        }
    }
}

@Composable
private fun Insignia(texto: String, color: Color, tam: Dp = 30.dp, modifier: Modifier = Modifier) {
    Box(
        modifier.size(tam).background(Color.White, CircleShape).border(2.dp, color, CircleShape),
        contentAlignment = Alignment.Center,
    ) { Text(texto, color = color, fontWeight = FontWeight.Black, fontSize = (tam.value * 0.55f).sp) }
}

/** La app: varias propuestas (programas) que se miran por encima y los seis partidos debajo. */
@Composable
private fun IlustracionApp() {
    val latido = rememberInfiniteTransition(label = "app")
    val escala by latido.animateFloat(1f, 1.12f, infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "e")
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(contentAlignment = Alignment.Center) {
            TarjetaMini(170.dp, modifier = Modifier.offset(x = (-40).dp, y = 10.dp).rotate(-8f))
            TarjetaMini(170.dp, modifier = Modifier.offset(x = 40.dp, y = 10.dp).rotate(8f))
            TarjetaMini(190.dp)
            Text("🤝", fontSize = 34.sp, modifier = Modifier.align(Alignment.TopEnd).offset(x = 30.dp, y = (-24).dp).scale(escala))
        }
        Spacer(Modifier.height(28.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Partido.entries.forEach { p ->
                Box(Modifier.background(colorDe(p), CircleShape).padding(horizontal = 8.dp, vertical = 5.dp)) {
                    Text(p.sigla, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 11.sp)
                }
            }
        }
    }
}

/** Adivina: una propuesta y seis botones de partido, uno acertado. */
@Composable
private fun IlustracionAdivina() {
    val latido = rememberInfiniteTransition(label = "adivina")
    val alfa by latido.animateFloat(0.3f, 1f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "a")
    val acertado = Partido.FA
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        TarjetaMini(220.dp, lineas = 2)
        Partido.entries.chunked(3).forEach { fila ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                fila.forEach { p ->
                    Box {
                        Box(
                            Modifier
                                .border(3.dp, if (p == acertado) MaterialTheme.colorScheme.onSurface.copy(alpha = alfa) else Color.Transparent, RoundedCornerShape(20.dp))
                                .padding(4.dp)
                                .size(width = 64.dp, height = 36.dp)
                                .background(colorDe(p).copy(alpha = if (p == acertado) 1f else 0.35f), RoundedCornerShape(18.dp)),
                            contentAlignment = Alignment.Center,
                        ) { Text(p.sigla, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp) }
                        if (p == acertado) Insignia("✓", Color(0xFF2E7D32), 22.dp, Modifier.align(Alignment.TopEnd).offset(x = 6.dp, y = (-6).dp))
                    }
                }
            }
        }
    }
}

/** Verdadero o falso: una propuesta, la pregunta por un partido y dos botones. */
@Composable
private fun IlustracionVF() {
    val latido = rememberInfiniteTransition(label = "vf")
    val giro by latido.animateFloat(-6f, 6f, infiniteRepeatable(tween(1100), RepeatMode.Reverse), label = "g")
    val t = LocalTextos.current
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Box {
            TarjetaMini(220.dp, lineas = 2)
            Box(
                Modifier.align(Alignment.TopEnd).offset(x = 18.dp, y = (-18).dp).rotate(giro)
                    .background(colorDe(Partido.PP), CircleShape).padding(horizontal = 12.dp, vertical = 6.dp),
            ) { Text("PP?", color = Color.White, fontWeight = FontWeight.Bold) }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            listOf(t.verdadero to Color(0xFF2E7D32), t.falso to Color(0xFFC62828)).forEachIndexed { i, (txt, c) ->
                Box {
                    Box(
                        Modifier.size(width = 110.dp, height = 46.dp).background(c.copy(alpha = if (i == 0) 1f else 0.4f), RoundedCornerShape(23.dp)),
                        contentAlignment = Alignment.Center,
                    ) { Text(txt, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp) }
                    if (i == 0) Insignia("✓", Color(0xFF2E7D32), 24.dp, Modifier.align(Alignment.TopEnd).offset(x = 6.dp, y = (-6).dp))
                }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("10", "20", "50").forEach {
                Box(
                    Modifier.border(1.5.dp, MaterialTheme.colorScheme.outline, CircleShape).padding(horizontal = 14.dp, vertical = 4.dp),
                ) { Text(it, style = MaterialTheme.typography.labelLarge) }
            }
        }
    }
}
