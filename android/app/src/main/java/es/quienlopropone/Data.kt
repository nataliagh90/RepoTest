package es.quienlopropone

import android.content.Context
import org.json.JSONArray

enum class Partido(val sigla: String, val nombre: String, val programa: String) {
    ERC("ERC", "Esquerra Republicana", "«Pel país. Per la gent. Pel futur.» (elecciones generales 2026)"),
    PP("PP", "Partido Popular", "«La Reconstrucción Nacional» (elecciones generales 2026)"),
    VOX("VOX", "Castilla y León", "«Un programa con sentido común» (autonómicas de Castilla y León 2026)"),
}

/** Otra propuesta, de otro partido, que coincide con esta. */
data class Coincidencia(
    val partido: Partido,
    val numero: Int,
    /** true = misma propuesta; false = parecida (mismo objetivo con otros medios). */
    val igual: Boolean,
    val resumen: String,
)

data class Iniciativa(
    val id: Int,
    val partido: Partido,
    val numero: Int,
    val pagina: Int,
    val tema: String,
    val seccion: String,
    /** Título en castellano (en ERC, traducido del catalán). */
    val titulo: String,
    /** Título original en catalán (sólo ERC; vacío en PP). */
    val original: String,
    val descripcion: String,
    val coincidencias: List<Coincidencia> = emptyList(),
    /** Resumen neutral de la medida («lo esencial»), igual de estilo para todos los partidos. */
    val esencial: String = "",
) {
    /** Partidos a los que se puede atribuir correctamente: el suyo y los que proponen lo mismo. */
    val partidosValidos: Set<Partido> = setOf(partido) + coincidencias.filter { it.igual }.map { it.partido }
    val compartida get() = partidosValidos.size > 1
}

object Repositorio {
    @Volatile private var cache: List<Iniciativa>? = null

    fun cargar(context: Context): List<Iniciativa> = cache ?: synchronized(this) {
        cache ?: leer(context).also { cache = it }
    }

    /** Busca una propuesta por partido y número (para mostrar el texto de las coincidencias). */
    fun buscar(todas: List<Iniciativa>, partido: Partido, numero: Int) =
        todas.firstOrNull { it.partido == partido && it.numero == numero }

    private fun leer(context: Context): List<Iniciativa> {
        val texto = context.assets.open("iniciativas.json").bufferedReader(Charsets.UTF_8).use { it.readText() }
        val arr = JSONArray(texto)
        return List(arr.length()) { i ->
            val o = arr.getJSONObject(i)
            Iniciativa(
                id = i,
                partido = Partido.valueOf(o.getString("partido")),
                numero = o.getInt("n"),
                pagina = o.getInt("pag"),
                tema = o.getString("tema"),
                seccion = o.getString("seccion"),
                titulo = o.getString("titulo"),
                original = o.optString("original", ""),
                descripcion = o.optString("desc", ""),
                coincidencias = o.optJSONArray("compartida")?.let { c ->
                    List(c.length()) { k ->
                        val x = c.getJSONObject(k)
                        val (p, n) = x.getString("con").split(" ")
                        Coincidencia(Partido.valueOf(p), n.toInt(), x.getString("nivel") == "igual", x.getString("resumen"))
                    }
                } ?: emptyList(),
                esencial = o.optString("esencial", ""),
            )
        }
    }
}
