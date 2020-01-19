package main.java.terminal;

import java.net.Socket;
import java.io.OutputStream;
import java.io.IOException;

public class SendMessage{
	private OutputStream out;

	public SendMessage(Socket cs){
		try{
			this.out = cs.getOutputStream();
		}
		catch(Exception e){
			System.out.println("Deu exceção no SendMessage: " + e.getMessage());
		}
	}

	public synchronized void sendServer(byte[] send){
		try{
			out.write(send);
			System.out.println("Enviei uma mensagem: ");
		}
		catch(Exception e){
			e.getMessage();
		}
	}

	public synchronized void sendServer(byte[] syn, byte[] send){
		try{
			out.write(syn);
			Thread.sleep(200);
			out.write(send);
			System.out.println("Enviei uma mensagem com Syn: ");

		}
		catch(Exception e){
			e.getMessage();
		}
	}
}