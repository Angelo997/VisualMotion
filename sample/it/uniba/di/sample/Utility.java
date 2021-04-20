package it.uniba.di.sample;

import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import javax.xml.transform.OutputKeys;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.stream.StreamResult;

import org.xml.sax.InputSource;

/**
 * 
 * <p>
 * Questa classe raccoglie tutti i metodi che vengono richiamati nel programma
 * principale per eseguire azioni ripetitive.
 * </p>
 *
 */
public class Utility {

	/**
	 * <p>
	 * Nome e percorso, relativo o assoluto, del file in cui saranno memorizzati
	 * eventuali errori catturati.
	 * </p>
	 */
	private static final String ERROR_LOG_PATH_AND_FILENAME = "error.log";

	/**
	 * <p>
	 * Riferimento al file contenente l'errore generato.
	 * </p>
	 */
	private static final String DETAIL_MESSAGE = "For more info please see '" + ERROR_LOG_PATH_AND_FILENAME + "' file.";

	/**
	 * <p>
	 * Constructor
	 * </p>
	 */
	public Utility() {
	}

	/**
	 * 
	 * @param exception
	 */
	public static void logError(Exception exception) {
		try (FileWriter fw = new FileWriter(new File(ERROR_LOG_PATH_AND_FILENAME));
				BufferedWriter bw = new BufferedWriter(fw)) {
			for (StackTraceElement stackTraceElement : exception.getStackTrace()) {
				fw.write(stackTraceElement.toString().concat("\n"));
			}
			logInfo(DETAIL_MESSAGE);
		} catch (IOException e) {
			logInfo("Error while accessing " + ERROR_LOG_PATH_AND_FILENAME);
		}
	}

	/**
	 * 
	 * @param info
	 */
	public static void logInfo(String info) {
		Program.progressList.add(info);
		scrollProgressList();
	}

	private static void scrollProgressList() {
		Program.progressList.select(Program.progressList.getItemCount() - 1);
	}
	
	/**
	 * 
	 * @param filename
	 * @return
	 */
	public static String xmlFormatter(String filename) {
		try {
			Transformer transformer = SAXTransformerFactory.newInstance().newTransformer();
			transformer.setOutputProperty(OutputKeys.INDENT, "yes");
			transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
			transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
			transformer.setOutputProperty("{http://xml.customer.org/xslt}indent-amount", "2");
			Source xmlSource = new SAXSource(new InputSource(new FileReader(new File(filename))));
			StreamResult res = new StreamResult(new ByteArrayOutputStream());
			transformer.transform(xmlSource, res);
			
			return new String(((ByteArrayOutputStream) res.getOutputStream()).toByteArray());
		} catch (TransformerFactoryConfigurationError | TransformerException | FileNotFoundException e) {
			logInfo("ERROR while formatting asmeta.xml file.\n ");
			logError((Exception) e);
			
			return null;
		}		
	}
}
