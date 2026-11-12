package es.quienlopropone

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class PartidaTest {
    // 30 iniciativas ficticias por partido.
    private val todas = Partido.entries.flatMap { p ->
        (1..30).map { n -> Iniciativa(p.ordinal * 100 + n, p, n, 1, "Tema", "Sección", "Título $p $n", "", "") }
    }

    @Test fun adivinaEstaEquilibrado() {
        repeat(200) { semilla ->
            val partida = Partida.adivina(todas, 10, Random(semilla))
            assertEquals(10, partida.preguntas.size)
            assertEquals(10, partida.preguntas.distinct().size)
            val porPartido = partida.preguntas.groupingBy { it.partido }.eachCount()
            assertEquals(3, porPartido.size)
            assertTrue(porPartido.values.all { it in 3..4 })
        }
    }

    @Test fun verdaderoFalsoMitadYMitad() {
        for (n in listOf(10, 20, 50)) for (p in Partido.entries) repeat(50) { semilla ->
            val partida = Partida.verdaderoFalso(todas, p, n, Random(semilla))
            assertEquals(n, partida.preguntas.size)
            assertEquals(n, partida.preguntas.distinct().size)
            assertEquals(n / 2, partida.preguntas.count { it.partido == p })
            val otros = partida.preguntas.filter { it.partido != p }.groupingBy { it.partido }.eachCount()
            assertEquals(2, otros.size)
            val (a, b) = otros.values.toList()
            assertTrue(kotlin.math.abs(a - b) <= 1)
        }
    }

    @Test fun correccion() {
        val partida = Partida.verdaderoFalso(todas, Partido.PP, 10, Random(1))
        val pp = todas.first { it.partido == Partido.PP }
        val vox = todas.first { it.partido == Partido.VOX }
        assertTrue(partida.corregir(pp, true))
        assertTrue(partida.corregir(vox, false))
        assertTrue(!partida.corregir(vox, true))
    }
}
