package es.quienlopropone

import androidx.compose.runtime.mutableStateListOf
import kotlin.random.Random

enum class Modo { ADIVINA, VERDADERO_FALSO }

/**
 * Una partida: lista fija de preguntas y las respuestas que se van dando.
 * En [Modo.VERDADERO_FALSO], [partido] es el partido por el que se pregunta.
 */
class Partida(
    val modo: Modo,
    val preguntas: List<Iniciativa>,
    val partido: Partido? = null,
) {
    /** true = acierto, false = fallo, en el orden de las preguntas respondidas. */
    val resultados = mutableStateListOf<Boolean>()
    val aciertos get() = resultados.count { it }

    /** La respuesta correcta en el modo verdadero/falso. */
    fun esDelPartido(i: Iniciativa) = i.partido == partido

    fun corregir(i: Iniciativa, eleccion: Partido) = eleccion == i.partido
    fun corregir(i: Iniciativa, verdadero: Boolean) = verdadero == esDelPartido(i)

    /** Clave para guardar el récord de esta configuración de partida. */
    val claveRecord get() = when (modo) {
        Modo.ADIVINA -> "record_adivina_${preguntas.size}"
        Modo.VERDADERO_FALSO -> "record_vf_${partido!!.name}_${preguntas.size}"
    }

    fun otraIgual(todas: List<Iniciativa>, rnd: Random = Random.Default) = when (modo) {
        Modo.ADIVINA -> adivina(todas, preguntas.size, rnd)
        Modo.VERDADERO_FALSO -> verdaderoFalso(todas, partido!!, preguntas.size, rnd)
    }

    companion object {
        /** [n] preguntas con los partidos lo más repartidos posible; el resto se asigna al azar. */
        fun adivina(todas: List<Iniciativa>, n: Int = 10, rnd: Random = Random.Default): Partida {
            val partidos = Partido.entries
            val cuantas = repartir(n, partidos, rnd)
            val preguntas = partidos.flatMap { p -> tomar(todas.filter { it.partido == p }, cuantas.getValue(p), rnd) }
            return Partida(Modo.ADIVINA, preguntas.shuffled(rnd))
        }

        /**
         * Mitad de propuestas del [partido] elegido y mitad de los demás,
         * repartidas a partes iguales entre ellos; si [n] es impar, la que sobra va al azar.
         */
        fun verdaderoFalso(todas: List<Iniciativa>, partido: Partido, n: Int, rnd: Random = Random.Default): Partida {
            var verdaderas = n / 2
            if (n % 2 == 1 && rnd.nextBoolean()) verdaderas++
            val otros = Partido.entries - partido
            val cuantasOtros = repartir(n - verdaderas, otros, rnd)
            val preguntas = tomar(todas.filter { it.partido == partido }, verdaderas, rnd) +
                otros.flatMap { p -> tomar(todas.filter { it.partido == p }, cuantasOtros.getValue(p), rnd) }
            return Partida(Modo.VERDADERO_FALSO, preguntas.shuffled(rnd), partido)
        }

        private fun repartir(n: Int, partidos: List<Partido>, rnd: Random): Map<Partido, Int> {
            val base = partidos.associateWith { n / partidos.size }.toMutableMap()
            partidos.shuffled(rnd).take(n % partidos.size).forEach { base[it] = base.getValue(it) + 1 }
            return base
        }

        private fun tomar(lista: List<Iniciativa>, n: Int, rnd: Random) = lista.shuffled(rnd).take(n)
    }
}
