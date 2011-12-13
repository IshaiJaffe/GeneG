from django.db import models
from djangotoolbox import fields
from django_mongodb_engine.fields import GridFSField
from django.contrib.auth.models import User

MAX_FIELD_LENGTH = 400


class Contact(models.Model):
    CubiclUser = models.ForeignKey(User,
        related_name='user_contacts',
        null=True,
        blank=True)
    MailAccount = models.CharField(max_length=MAX_FIELD_LENGTH)
    ContactEmail = models.CharField(max_length=MAX_FIELD_LENGTH)
    FamilyName = models.CharField(max_length=MAX_FIELD_LENGTH)
    FullName = models.CharField(max_length=MAX_FIELD_LENGTH)
    GivenName = models.CharField(max_length=MAX_FIELD_LENGTH)

    def __unicode__(self):
    	return self.ContactEmail


class Attachment(models.Model):
    filename = models.CharField(max_length=MAX_FIELD_LENGTH)
    ContentType = models.CharField(max_length=MAX_FIELD_LENGTH)
    ContentDisposition = models.CharField(
        max_length=MAX_FIELD_LENGTH,
        null=True)
    ContentTransferEncoding = models.CharField(
        max_length=MAX_FIELD_LENGTH)
    XAttachmentId = models.CharField(
        max_length=MAX_FIELD_LENGTH,
        null=True)
    blob = GridFSField(editable=False)

class Email(models.Model):
    CubiclUser = models.ForeignKey(User,
        related_name='user_email_messages',
        null=True,
        blank=True)
    # note from which mailbox arrived
    MailBox = models.CharField(max_length=MAX_FIELD_LENGTH)
    # tagging for our purpose
    EmailTag = models.CharField(max_length=MAX_FIELD_LENGTH)
    # repeating fields
    DeliveredTo = models.CharField(max_length=MAX_FIELD_LENGTH)
    ReceivedSPF = fields.ListField(models.CharField(max_length=MAX_FIELD_LENGTH, editable=False), editable=False)
    Received = fields.ListField(models.CharField(max_length=MAX_FIELD_LENGTH, editable=False), editable=False)
    # Non recurrent fields
    ReturnPath = models.CharField(max_length=MAX_FIELD_LENGTH)
    AuthenticationResults = models.CharField(max_length=MAX_FIELD_LENGTH)
    DKIMSignature = models.CharField(max_length=MAX_FIELD_LENGTH)
    Sender = models.CharField(max_length=MAX_FIELD_LENGTH)
    XBeenThere = models.CharField(max_length=MAX_FIELD_LENGTH)
    References = models.CharField(max_length=MAX_FIELD_LENGTH)
    From = models.CharField(max_length=MAX_FIELD_LENGTH)
    InReplyTo = models.CharField(max_length=MAX_FIELD_LENGTH)
    MimeVersion = models.CharField(max_length=MAX_FIELD_LENGTH)
    Date = models.CharField(max_length=MAX_FIELD_LENGTH)
    MessageID = models.CharField(max_length=MAX_FIELD_LENGTH)
    Subject = models.CharField(max_length=MAX_FIELD_LENGTH)
    To = models.CharField(max_length=MAX_FIELD_LENGTH)
    Cc = models.CharField(max_length=MAX_FIELD_LENGTH)
    XOriginalSender = models.CharField(max_length=MAX_FIELD_LENGTH)
    XOriginalAuthenticationResults = models.CharField(max_length=MAX_FIELD_LENGTH)
    Precedence = models.CharField(max_length=MAX_FIELD_LENGTH)
    Mailinglist = models.CharField(max_length=MAX_FIELD_LENGTH)
    ListID = models.CharField(max_length=MAX_FIELD_LENGTH)
    XGoogleGroupId = models.CharField(max_length=MAX_FIELD_LENGTH)
    ListPost = models.CharField(max_length=MAX_FIELD_LENGTH)
    ListHelp = models.CharField(max_length=MAX_FIELD_LENGTH)
    ListArchive = models.CharField(max_length=MAX_FIELD_LENGTH)
    ContentType = models.CharField(max_length=MAX_FIELD_LENGTH)
    MessageText = models.TextField()
    MessageTextDecoded = models.TextField()
    attachements = fields.ListField(models.ForeignKey(Attachment), editable=False)
    def __unicode__(self):
        return "%s | %s " % (self.From, self.Subject)

