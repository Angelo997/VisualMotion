package it.uniba.di.sample;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class Executor extends Utility {

	public static Process p = null;

	public static void execute() {
		p = null;
		ProcessBuilder pb = null;
		pb = new ProcessBuilder("asmeta\\sample\\run.bat");
		
		try {
			p = pb.start();
		} catch (IOException e2) {
			logInfo("ERROR while initializing the process.\n ");
			logError(e2);
		}
		InputStreamReader isr = new InputStreamReader(p.getInputStream());
		BufferedReader br = new BufferedReader(isr);

		String lineRead;
		try {
			while ((lineRead = br.readLine()) != null) {
			}
		} catch (IOException e1) {
			logInfo("ERROR while executing the process:.\n ");
			logError(e1);
		}

		try {
			p.waitFor();
		} catch (InterruptedException e) {
			logInfo("ERROR while waiting for the process.\n ");
			logError(e);
			Thread.currentThread().interrupt();
		}
	}
}
