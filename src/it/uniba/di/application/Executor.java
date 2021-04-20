package it.uniba.di.application;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import it.uniba.di.support.Utility;

public class Executor extends Utility {

	public static final String RESULT_OUTPUT_FILE = ASMETA_LOG_PATH + "dump.txt";

	public static Process p = null;

	/**
	 * 
	 * @param inputFileName
	 * @param outputFileName
	 */
	public static void execute(String inputFileName, String outputFileName) {
		p = null;
		ProcessBuilder pb = null;
		pb = new ProcessBuilder("runAsmetaS.bat", inputFileName, outputFileName);
		try {
			p = pb.start();
		} catch (IOException e2) {
			error(e2);
		}
		InputStreamReader isr = new InputStreamReader(p.getInputStream());
		BufferedReader br = new BufferedReader(isr);

		String lineRead;
		try {
			while ((lineRead = br.readLine()) != null) {
			}
		} catch (IOException e1) {
			error(e1);
		}

		try {
			p.waitFor();
		} catch (InterruptedException e) {
			error(e);
			Thread.currentThread().interrupt();
		}
	}

	/**
	 * 
	 */
	public static void interrupt() {
		Process pr = null;
		ProcessBuilder pb = new ProcessBuilder("kill.bat");
		try {
			pr = pb.start();
		} catch (IOException e2) {
			error(e2);
		}
		InputStreamReader isr = new InputStreamReader(p.getInputStream());
		BufferedReader br = new BufferedReader(isr);

		String lineRead;
		try {
			while ((lineRead = br.readLine()) != null) {
			}
		} catch (IOException e1) {
			error(e1);
		}

		try {
			pr.waitFor();
		} catch (InterruptedException e) {
			error(e);
			Thread.currentThread().interrupt();
		}
	}

}
